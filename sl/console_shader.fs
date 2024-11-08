#version 330

// Text-console grid shader

const vec3 WHITE = vec3(1.0);
const vec3 BLACK = vec3(0.0);

in vec2 fragTexCoord;
out vec4 finalColor;

uniform sampler2D font;     // the bitmap font image (e.g. cp437)

uniform vec2 grid_size = vec2(80.0, 50.0);
uniform vec2 font_size = vec2(16.0, 16.0);
uniform float cw = 20.0;
uniform float ch = 20.0;

// texture size in px == console grid size in cells (e.g. 80 x 50)
uniform sampler2D bg_tex;   // background grid colors
uniform sampler2D fg_tex;   // foreground grid colors
uniform sampler2D chr_tex;  // glyph values in red channel


void main() {
	// get font and console-canvas sizes in pixels
	vec2 ft_img_size = vec2(font_size.x*cw, font_size.y*ch);
	vec2 canvas_size = vec2(grid_size.x*cw, grid_size.y*ch);

	// get the glyph value (stored in the red and green channels), and scale it to 0-255
	vec4 glyph_col = texture(chr_tex, fragTexCoord);
	float glyph = floor(glyph_col.r + glyph_col.g) * 255.0;

	// get the respective tile coords on the font, in pixels, normalized
	vec2 guv = vec2(
		floor(mod(glyph, font_size.x))  / ft_img_size.x * cw,
		floor(glyph / font_size.x)      / ft_img_size.y * ch
	);

	// get the pixel we're currently at in the current tile, as an offset to add to the 'guv'
	vec2 ofs = vec2(
		mod(fragTexCoord.x * canvas_size.x, cw)   / ft_img_size.x,
		mod(fragTexCoord.y * canvas_size.y, ch)   / ft_img_size.y
	);

	vec2 pixuv = guv + ofs;

	// Get the pixel color at the tile coords IN THE FONT IMAGE, offset to the current pixel in the tile
	vec4 px_col = texture(font, pixuv);
	// vec4 px_col = texture(font, fragTexCoord);
	// finalColor = px_col;

	vec4 bg_col = texture(bg_tex, fragTexCoord);
	vec4 fg_col = texture(fg_tex, fragTexCoord);

	// If 'px_col' is black (excluding alpha), that means this pixel belongs
	// to the space around the glyph, otherwise this pixel is from the glyph
	// itself.
	if (px_col.rgb == BLACK.rgb) {
		finalColor = bg_col;
	} else {
		finalColor = vec4(fg_col.rgb * px_col.rgb, fg_col.a);
		// finalColor = texture(fg_tex, fragTexCoord);
	}

	// tests
	// if (px_col.rgb == BLACK) {
		// finalColor = vec4(fragTexCoord, 1.0, 1.0);
		// finalColor = px_col;
		// finalColor = texture(font, fragTexCoord);

		// if (guv.x != 0 && guv.y != 0) {finalColor = vec4(fragTexCoord, 1.0, 1.0); }
		// if (guv.x < 0) {finalColor = vec4(fragTexCoord, 1.0, 1.0); }
		// if (ofs.x != 0.0 || ofs.y != 0.0) {finalColor = vec4(fragTexCoord, 1.0, 1.0); }
		// if (pixuv.x > 1.0 || pixuv.y > 1.0 || pixuv.x < 0.0 || pixuv.y < 0.0) {finalColor = vec4(fragTexCoord, 1.0, 1.0); }

		// if (glyph_col.r == 219.0/255.0) {finalColor = vec4(fragTexCoord, 1.0, 1.0); }
		// if (glyph == 219) {finalColor = vec4(fragTexCoord, 1.0, 1.0); }
		// if (guv.y == 0.8125) {finalColor = vec4(fragTexCoord, 1.0, 1.0); }



		// float r = ofs.x >= 0 ? 1 : 0;
		// float g = ofs.y >= 0 ? 1 : 0;
		// finalColor = vec4(r, g, 0, 1);
	// }
}

