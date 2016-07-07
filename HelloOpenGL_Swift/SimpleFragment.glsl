uniform sampler2D Texture;
varying mediump vec2 TexCoordOut;
varying lowp vec4 DestinationColor;

void main(void) {
    gl_FragColor = DestinationColor * texture2D(Texture, TexCoordOut);
//    gl_FragColor = vec4(DestinationColor.x * TexCoordOut.x, DestinationColor.y * TexCoordOut.y, DestinationColor.z, DestinationColor.w);
}
