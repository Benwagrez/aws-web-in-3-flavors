const scrollingImages = document.querySelector('.scrolling-images');
const images = scrollingImages.querySelectorAll('img');
const imageWidth = images[0].clientWidth;

// Clone the images for a seamless loop
const totalImages = images.length;
for (let i = 0; i < totalImages; i++) {
  const clone = images[i].cloneNode(true);
  scrollingImages.appendChild(clone);
}
let currentPosition = scrollingImages.clientWidth/4;
let prevPosition = currentPosition; // Store previous position
let animationFrameId;
let isPaused = false;

function scrollImages(timestamp) {
  if (!isPaused) {
    const timePassed = timestamp - lastTimestamp || 0;
    lastTimestamp = timestamp;

    currentPosition -= (timePassed / 10); // Adjust speed as needed
    scrollingImages.style.transform = `translateX(${currentPosition}px)`;

    if (currentPosition <= -scrollingImages.clientWidth/4) {
      currentPosition = scrollingImages.clientWidth/4 - (timePassed / 5);
    }
  }
  animationFrameId = requestAnimationFrame(scrollImages);
}

let lastTimestamp = 0;
animationFrameId = requestAnimationFrame(scrollImages);

scrollingImages.addEventListener('mouseover', () => {
  isPaused = true;
  cancelAnimationFrame(animationFrameId);
  prevPosition = currentPosition; // Store previous position
});

scrollingImages.addEventListener('mouseout', () => {
  isPaused = false;
  currentPosition = prevPosition; // Resume from previous position
  lastTimestamp = performance.now(); // Reset last timestamp
  animationFrameId = requestAnimationFrame(scrollImages);
});
