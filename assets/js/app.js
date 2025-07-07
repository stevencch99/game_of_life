// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import 'phoenix_html';
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from 'phoenix';
import { LiveSocket } from 'phoenix_live_view';
import topbar from '../vendor/topbar';

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute('content');

// ---- Utility helpers (temporary, will move to separate file later) ----
const coordToKey = (x, y) => `${x},${y}`;
const keyToCoord = (key) => key.split(',').map(Number);

const applyCellsDiff = (set, add = [], remove = []) => {
  add.forEach(([x, y]) => set.add(coordToKey(x, y)));
  remove.forEach(([x, y]) => set.delete(coordToKey(x, y)));
};

const parseLiveCellsPayload = (payload) => {
  if (!payload) return { add: [], remove: [], full: [] };
  if (Array.isArray(payload.live_cells)) {
    return { full: payload.live_cells };
  }
  return {
    add: payload.add || [],
    remove: payload.remove || [],
  };
};

// ----------------------------------------------------------------------
const Hooks = {};
Hooks.GameCanvas = {
  mounted() {
    this.initCanvas();
    this.registerEvents();
    this.listenLiveView();
  },

  //---------------- initialization ------------------
  initCanvas() {
    this.canvas = this.el;
    this.ctx = this.canvas.getContext('2d');
    this.gridSize = parseInt(this.el.dataset.gridSize);

    // State
    this.liveCells = new Set();
    this.updateLiveCellsFromElement();

    this.resizeCanvas();
    this.drawGrid();
    this.drawCells();
  },

  //---------------- event listeners ------------------
  registerEvents() {
    // Resize
    window.addEventListener('resize', () => this.resizeCanvas());

    // Click toggle
    this.el.addEventListener('click', (e) => {
      const rect = this.canvas.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      const cellSize = this.canvas.width / this.gridSize;

      const cellX = Math.floor(x / cellSize);
      const cellY = Math.floor(y / cellSize);

      this.pushEvent('toggle_cell', { x: cellX, y: cellY });
    });
  },

  //---------------- Phoenix LiveView events ------------------
  listenLiveView() {
    this.handleEvent('update_cells', (event) => {
      try {
        const { full, add, remove } = parseLiveCellsPayload(event.payload ?? event);

        if (full) {
          // Replace entire set
          this.liveCells = new Set(full.map(([x, y]) => coordToKey(x, y)));
        } else {
          applyCellsDiff(this.liveCells, add, remove);
        }

        // Sync to dataset for LV re-mount
        this.el.dataset.liveCells = JSON.stringify(Array.from(this.liveCells).map(keyToCoord));
        this.drawCells();
      } catch (error) {
        console.error('Error in update_cells handler:', error, 'Event data:', event);
      }
    });
  },

  //---------------- helpers ------------------
  updateLiveCellsFromElement() {
    try {
      const liveCellsData = this.el.dataset.liveCells;
      if (liveCellsData) {
        const cells = JSON.parse(liveCellsData);
        this.liveCells = new Set(cells.map(([x, y]) => `${x},${y}`));
      } else {
        this.liveCells = new Set();
      }
    } catch (error) {
      console.error('Error parsing live cells:', error);
      this.liveCells = new Set();
    }
  },

  resizeCanvas() {
    const size = Math.min(this.el.parentElement.clientWidth, 700);
    this.canvas.width = size;
    this.canvas.height = size;
    this.drawGrid();
    this.drawCells();
  },

  // Draw static grid lines; called on resize only
  drawGrid() {
    const cellSize = this.canvas.width / this.gridSize;
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

  },

  // Draw live cells only
  drawCells() {
    const cellSize = this.canvas.width / this.gridSize;
    this.ctx.fillStyle = 'rgb(18, 18, 22)';

    // clear previous cells layer
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

    this.liveCells.forEach((cell) => {
      const [x, y] = cell.split(',').map(Number);
      if (Number.isFinite(x) && Number.isFinite(y)) {
        this.ctx.fillRect(x * cellSize, y * cellSize, cellSize, cellSize);
      } else {
        console.warn('Invalid cell coordinates:', cell);
      }
    });

    // Draw grid lines
    this.ctx.strokeStyle = '#e5e7eb'; // zinc-200
    this.ctx.lineWidth = 1;
    for (let i = 0; i <= this.gridSize; i++) {
      const pos = i * cellSize;
      // Vertical lines
      this.ctx.beginPath();
      this.ctx.moveTo(pos, 0);
      this.ctx.lineTo(pos, this.canvas.height);
      this.ctx.stroke();
      // Horizontal lines
      this.ctx.beginPath();
      this.ctx.moveTo(0, pos);
      this.ctx.lineTo(this.canvas.width, pos);
      this.ctx.stroke();
    }
  },
};

let liveSocket = new LiveSocket('/live', Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: '#29d' }, shadowColor: 'rgba(0, 0, 0, .3)' });
window.addEventListener('phx:page-loading-start', (_info) => topbar.show(300));
window.addEventListener('phx:page-loading-stop', (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
