
// Canvas draw
async function drawImage(img, ctx, dx, dy) {
  ctx.drawImage(img, dx, dy);
}
async function drawImageCentered(img, ctx, dx, dy) {
  ctx.drawImage(img, dx - img.width/2, dy - img.height/2);
}
async function drawImageCenteredRotated(img, ctx, dx, dy, angle) {
  ctx.save();
  ctx.translate(dx, dy);
  ctx.rotate(degToRad(angle));
  ctx.translate(-img.width/2, -img.width/2);
  ctx.drawImage(img, 0, 0);
  ctx.restore();
}
function getMousePos(canvas, evt) {
  var rect = canvas.getBoundingClientRect();
  return {
    x: evt.clientX - rect.left,
    y: evt.clientY - rect.top
  };
}


// Canvas misc
function canvasLoop(loopFunc){
  setInterval(loopFunc, 1000/60);
}

function createMouseMoveEvent(canvas, callback){
  canvas.addEventListener('mousemove', function(evt) {
    var mousePos = getMousePos(canvas, evt);
    callback(mousePos.x, mousePos.y);
  }, false);
}

function radToDeg(radians)
{
  var pi = Math.PI;
  return radians * (180/pi);
}
function degToRad(degrees)
{
  var pi = Math.PI;
  return degrees * (pi/180);
}



// GML
function angle_difference(dest, src){
  return ((((dest - src) % 360.0) + 540.0) % 360.0) - 180.0;
}