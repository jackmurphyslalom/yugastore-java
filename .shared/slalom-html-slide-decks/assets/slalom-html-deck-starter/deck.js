const slides = [...document.querySelectorAll(".slide-frame")];
const count = document.querySelector("[data-slide-count]");
let active = 0;

function showSlide(index) {
  active = Math.max(0, Math.min(slides.length - 1, index));
  slides.forEach((slide, i) => slide.hidden = i !== active);
  if (count) count.textContent = `${active + 1} / ${slides.length}`;
  if (location.hash !== `#slide-${active + 1}`) {
    history.replaceState(null, "", `#slide-${active + 1}`);
  }
}

window.addEventListener("keydown", (event) => {
  if (["ArrowRight", "PageDown", " "].includes(event.key)) showSlide(active + 1);
  if (["ArrowLeft", "PageUp"].includes(event.key)) showSlide(active - 1);
  if (event.key === "Home") showSlide(0);
  if (event.key === "End") showSlide(slides.length - 1);
});

document.querySelector("[data-prev]")?.addEventListener("click", () => showSlide(active - 1));
document.querySelector("[data-next]")?.addEventListener("click", () => showSlide(active + 1));

const hashSlide = Number((location.hash.match(/slide-(\d+)/) || [])[1]);
showSlide(hashSlide ? hashSlide - 1 : 0);
