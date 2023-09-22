#include <stdbool.h>
	
volatile int pixel_buffer_start; // global variable

void wait_for_vsync() {	
	volatile int* pixel_ctrl_ptr = (int *) 0xFF203020;
	register int status;
	*pixel_ctrl_ptr = 1;
	
	status = *(pixel_ctrl_ptr + 3);
	while ((status & 0x01) != 0) {
		status = *(pixel_ctrl_ptr + 3);
	}
}

void plot_pixel(int x, int y, short int line_color)
{
	*(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

void draw_box(int x, int y, short int line_color) {
	plot_pixel(x, y, line_color);
	plot_pixel(x - 1, y, line_color);
	plot_pixel(x + 1, y, line_color);
	plot_pixel(x, y - 1, line_color);
	plot_pixel(x - 1, y - 1, line_color);
	plot_pixel(x + 1, y - 1, line_color);
	plot_pixel(x, y + 1, line_color);
	plot_pixel(x - 1, y + 1, line_color);
	plot_pixel(x + 1, y + 1, line_color);
}

void clear_screen() {

int i,j;
	for (i = 0; i < 320; i++) {
		for (j = 0; j < 240; j++) {
			plot_pixel(i, j, 0); 
		}
	}
}

void draw_line(int x0, int y0, int x1, int y1, short int line_color) {
	bool is_steep = abs(y1 - y0) > abs(x1 - x0);
	
	if (is_steep) { 
		int t = x0;
		x0 = y0;
		y0 = t;
		
		t = x1;
		x1 = y1;
		y1 = t; 
	}
	
	if (x0 > x1) { 
		int temp = x0;
		x0 = x1;
		x1 = temp;
		temp = y0;
		y0 = y1;
		y1 = temp;
	}
	
	int deltax = x1 - x0;
	int deltay = abs(y1 - y0);
	int error = -(deltax / 2);
	int y = y0;
	int y_step;
	
	if (y0 < y1) {
		y_step = 1;
	} else {
		y_step = -1;
	}
	 
	int x;
	for (x = x0; x <= x1; x++) {
		if (is_steep) {
			plot_pixel(y, x, line_color);
		} else {
			plot_pixel(x, y, line_color);
		}

		error = error + deltay;
		if (error > 0) {
			y = y + y_step;
			error = error - deltax;
		}	
	}
}



int main(void)
{
	volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
	// declare other variables(not shown)
	// initialize location and direction of rectangles(not shown)
	/* set front pixel buffer to start of FPGA On-chip memory */
	*(pixel_ctrl_ptr + 1) = 0xC8000000; // first store the address in the
	// back buffer
	/* now, swap the front/back buffers, to set the front buffer location */
	wait_for_vsync();
	/* initialize a pointer to the pixel buffer, used by drawing functions */
	pixel_buffer_start = *pixel_ctrl_ptr;
	clear_screen(); // pixel_buffer_start points to the pixel buffer
	/* set back pixel buffer to start of SDRAM memory */
	*(pixel_ctrl_ptr + 1) = 0xC0000000;
	pixel_buffer_start = *(pixel_ctrl_ptr + 1); // we draw on the back buffer
	clear_screen(); // pixel_buffer_start points to the pixel buffer
	 
	
	int x[8];
	int y[8];
	int directions[] = {-1, 1};
	int dirX[8];
	int dirY[8];
	int oldDirX[8];
	int oldDirY[8];
	short int colors[8];
	int i;
	for (i = 0; i < 8; i++) {
		x[i] = rand() % 320;
		y[i] = rand() % 240;
		dirX[i] = directions[rand() % 2];
		dirY[i] = directions[rand() % 2];
		oldDirX[i] = dirX[i];
		oldDirY[i] = dirY[i];
		colors[i] = (rand() % 0xFFF0) + 0xF;
	} 
	
	while (1)
	{
	/* Erase any boxes and lines that were drawn in the last iteration */
	//draw_line(x1 - (dirX * 2), y1 - (dirY * 2), 250, y1 - (dirY * 2), 0);
	// code for drawing the boxes and lines (not shown)
	//draw_line(50, yC, 250, yC, 0x001F); // this line is blue 
	// code for updating the locations of boxes (not shown)
	
 
	for (i = 0; i < 7; i++) {
		draw_line(x[i] - oldDirX[i], y[i] - oldDirY[i], x[i+1] - oldDirX[i+1], y[i+1] - oldDirY[i+1], 0);
	}
	draw_line(x[0] - oldDirX[0], y[0] - oldDirY[0], x[7] - oldDirX[7], y[7] - oldDirY[7], 0);
		
	for (i = 0; i <= 7; i++) {
		draw_box(x[i] - oldDirX[i], y[i] - oldDirY[i], 0);

		x[i] += dirX[i];
		y[i] += dirY[i];

		draw_box(x[i], y[i], colors[i]);	

		oldDirX[i] = dirX[i];
		oldDirY[i] = dirY[i];

		if (x[i] == 2) {
			dirX[i] = 1;
		}
		if (x[i] == 318) {
			dirX[i] = -1;
		}

		if (y[i] == 2) {
			dirY[i] = 1;
		}
		if (y[i] == 238) {
			dirY[i] = -1;
		}
	}
		
	for (i = 0; i < 7; i++) {
		draw_line(x[i], y[i], x[i+1], y[i+1], colors[i]);
	}
		
	draw_line(x[0], y[0], x[7], y[7], colors[0]);
	
		
	wait_for_vsync(); // swap front and back buffers on VGA vertical sync
	
		
	pixel_buffer_start = *(pixel_ctrl_ptr + 1); // new back buffer
	
	}
}

