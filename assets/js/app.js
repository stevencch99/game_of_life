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

const Hooks = {};
Hooks.GameCanvas = {
  mounted() {
    this.canvas = this.el;
    this.ctx = this.canvas.getContext('2d');
    this.gridSize = parseInt(this.el.dataset.gridSize);
    this.updateLiveCellsFromElement();

    this.resizeCanvas();
    this.drawGrid();

    window.addEventListener('resize', () => this.resizeCanvas());

    this.el.addEventListener('click', (e) => {
      const rect = this.canvas.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      const cellSize = this.canvas.width / this.gridSize;

      const cellX = Math.floor(x / cellSize);
      const cellY = Math.floor(y / cellSize);

      this.pushEvent('toggle_cell', { x: cellX, y: cellY });
    });

    this.handleEvent('update_cells', (event) => {
      try {
        const live_cells = event.live_cells || (event.payload && event.payload.live_cells) || [];

        // Convert array of [x,y] to Set of "x,y" strings
        this.liveCells = new Set(
          live_cells
            .map((cell) => {
              if (Array.isArray(cell) && cell.length === 2) {
                return `${cell[0]},${cell[1]}`;
              }
              console.warn('Invalid cell format:', cell);
              return null;
            })
            .filter(Boolean)
        );

        this.el.dataset.liveCells = JSON.stringify(live_cells);
        this.drawGrid();
      } catch (error) {
        console.error('Error in update_cells handler:', error, 'Event data:', event);
      }
    });
  },

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
  },

  drawGrid() {
    const cellSize = this.canvas.width / this.gridSize;
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

    // Draw live cells
    this.ctx.fillStyle = 'rgb(18, 18, 22)';

    if (this.liveCells.size === 0) {
    }

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
