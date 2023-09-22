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


void clear_screen() {
	for (int i = 0; i < 320; i++) {
		for (int j = 0; j < 240; j++) {
			plot_pixel(i, j, 0); 
		}
	}
}

void draw_line(int x0, int y0, int x1, int y1, short int line_color) {
	//plot_pixel(x1,y1,line_color);
	bool is_steep = abs(y1 - y0) > abs(x1 - x0);
	
	//if (is_steep) {
	//	swap(x0, y0)			
	//	swap(x1, y1)
	//}
	
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
	 
	for (int x = x0; x <= x1; x++) {
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
	
 
	while (1)
	{
	/* Erase any boxes and lines that were drawn in the last iteration */
	draw_line(0, 0, 150, 150, 0); // this line is blue
	draw_line(150, 150, 319, 0, 0); // this line is green
	draw_line(0, 239, 319, 239, 0); // this line is red
	draw_line(319, 0, 0, 239, 0); 
		
	draw_line(0, 0, 150, 150, 0x001F); // this line is blue
	draw_line(150, 150, 319, 0, 0x07E0); // this line is green
	draw_line(0, 239, 319, 239, 0xF800); // this line is red
	draw_line(319, 0, 0, 239, 0xF81F); 
	 
	wait_for_vsync(); // swap front and back buffers on VGA vertical sync
	
		
	pixel_buffer_start = *(pixel_ctrl_ptr + 1); // new back buffer
	
	}
}