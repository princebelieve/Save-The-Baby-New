// Keep native links/forms functional if JavaScript is unavailable.
const pending = new Map();
function begin(control, caption, seconds) {
  if (pending.has(control)) return false;
  const original = control.textContent;
  control.textContent = caption;
  control.setAttribute('aria-busy', 'true');
  control.setAttribute('aria-disabled', 'true');
  const reset = () => {
    control.textContent = original;
    control.removeAttribute('aria-busy');
    control.removeAttribute('aria-disabled');
    pending.delete(control);
  };
  pending.set(control, {reset, timer: setTimeout(() => {
    reset();
    status.textContent = 'Still here? You can try again. Make sure the game is running.';
  }, seconds * 1000)});
  return true;
}
const status = document.createElement('p');
status.setAttribute('role', 'status');
status.setAttribute('aria-live', 'polite');
document.querySelector('main').append(status);
document.querySelector('form')?.addEventListener('submit', event => {
  const button = event.target.querySelector('button[type="submit"]');
  if (!begin(button, 'Opening Google…', 20)) event.preventDefault();
  else status.textContent = 'Connecting to Google. Please wait…';
});
document.querySelector('#return-to-game')?.addEventListener('click', event => {
  if (!begin(event.currentTarget, 'Opening game…', 5)) event.preventDefault();
  else status.textContent = 'Opening Save the Baby. If it stays closed, switch back to the game or try again.';
});
window.addEventListener('pageshow', () => {
  for (const {reset, timer} of pending.values()) { clearTimeout(timer); reset(); }
  status.textContent = '';
});
