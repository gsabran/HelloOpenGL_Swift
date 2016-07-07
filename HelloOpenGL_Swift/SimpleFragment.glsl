uniform sampler2D Texture;
varying mediump vec2 CameraTextureCoord;
varying lowp vec4 DestinationColor;

void main(void) {
    gl_FragColor = vec4(DestinationColor.x * CameraTextureCoord.x, DestinationColor.y * CameraTextureCoord.y, DestinationColor.z, DestinationColor.w);}
