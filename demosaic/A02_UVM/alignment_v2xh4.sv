// 取出1行数据，放在 buff里

class readbin #(int BITS = 8, int HEIGHT = 768, int WIDTH = 768, int h_chan = 4, int v_chan = 2);

    string         bin_path            ;
    integer        height   = HEIGHT   ;
    integer        width    = WIDTH    ;

    bit [BITS-1:0] buff_up  [0:WIDTH-1] ; // 暂存一行 pixel values
    bit [BITS-1:0] buff_down[0:WIDTH-1] ; // 暂存一行 pixel values
    
    integer fd, idx = 0;
    integer row_num = 0;

    function set(input string BIN_path);
        bin_path = BIN_path;
        fd = $fopen(bin_path, "rb");
        if (!fd) begin 
            $error("binfile could not be open: ", bin_path); 
            return; 
        end
    endfunction

// 从 bin文件中读取 pixel。 每次调用 gen_pic 只能获得一行数据
    function void gen_pic(output bit [BITS-1:0] data[0:7]) ; 
        if (idx % WIDTH == 0) begin 

            // 取出上面一行全部数据
            for (integer j = 0; j < WIDTH; j++) begin 
                for (integer c = 0; c < BITS/8; c = c + 1) begin 
                    $fscanf(fd, "%c", buff_up[j][(c*8)+:8]);
                end
            end
            
            // 取出下面一行全部数据
            for (integer k = 0; k < WIDTH; k++) begin 
                for (integer c = 0; c < BITS/8; c = c + 1) begin 
                    $fscanf(fd, "%c", buff_down[k][(c*8)+:8]);
                end
            end
            row_num = row_num + 1;
            idx     = 0;
            
        end

        data[0] = buff_up  [idx + 0]; data[1] = buff_up  [idx + 1]; data[4] = buff_up  [idx + 2]; data[5] = buff_up  [idx + 3];
        data[2] = buff_down[idx + 0]; data[3] = buff_down[idx + 1]; data[6] = buff_down[idx + 2]; data[7] = buff_down[idx + 3];
        
        //$display("data[0] = %0d, \tdata[1] = %0d, \tdata[4] = %0d, \tdata[5] = %0d"           , data[0], data[1], data[4], data[5]);
        //$display("data[2] = %0d, \tdata[3] = %0d, \tdata[6] = %0d, \tdata[7] = %0d, idx = %0d", data[2], data[3], data[6], data[7], idx);
        
        idx = idx + 4;
        
        if ((row_num == height/v_chan) && (idx == width) ) begin 
            $display("\nAll pixels from such path [%0s] has been read. \n", bin_path);
            $fclose(fd);
        end
    endfunction
endclass

/*
module testOverride;

    parameter  bits     = 8;
    parameter  height   = 512;
    parameter  width    = 768;
    parameter  h_chan   = 4  ;
    parameter  v_chan   = 2  ;
    picture_pixel#(.BITS(bits), .HEIGHT(height), .WIDTH(width)) pic;
    string     bin_path = "/home/guhu/Desktop/UVM_test/B03_ISP/D01_input_img/raw_512x768_rggb.bin";
    bit [bits-1:0] data[0:7];
    //bit [bits-1:0] data2[0:width-1];
    initial begin
        pic = new();
        //p1.height   = 512;
        //p1.width    = 768;
        //p1.bin_path = "./raw_512x768_rggb.bin";
        pic.set(bin_path);
        $display("height = %0d, width = %0d", pic.height, pic.width);
        for (integer i = 0; i < width/h_chan * height /v_chan; i++) begin 
            pic.gen_pic(data);
        end
    end
endmodule
*/

// 此时会输出4张图像，每个像素只支持1个字节，如果是双字节，还需要进一步修改。
module save2bin #( 
    parameter FILE0  = "outr.bin", 
    parameter FILE1  = "outg.bin", 
    parameter FILE2  = "outb.bin", 
    parameter BITS   = 8, 
    parameter WIDTH  = 320)(
	input            xclk   ,
	input            rst_n  ,
	input            data_en,
	input            done  ,
    input [BITS-1:0] i_data_r_0 , i_data_g_0, i_data_b_0,
    input [BITS-1:0] i_data_r_1 , i_data_g_1, i_data_b_1,
    input [BITS-1:0] i_data_r_2 , i_data_g_2, i_data_b_2,
    input [BITS-1:0] i_data_r_3 , i_data_g_3, i_data_b_3,
    input [BITS-1:0] i_data_r_4 , i_data_g_4, i_data_b_4,
    input [BITS-1:0] i_data_r_5 , i_data_g_5, i_data_b_5,
    input [BITS-1:0] i_data_r_6 , i_data_g_6, i_data_b_6,
    input [BITS-1:0] i_data_r_7 , i_data_g_7, i_data_b_7 );

    reg [BITS-1:0] r_buff_up   [0:WIDTH-1];
    reg [BITS-1:0] r_buff_down [0:WIDTH-1];

    reg [BITS-1:0] g_buff_up   [0:WIDTH-1];
    reg [BITS-1:0] g_buff_down [0:WIDTH-1];

    reg [BITS-1:0] b_buff_up   [0:WIDTH-1];
    reg [BITS-1:0] b_buff_down [0:WIDTH-1];

	integer c, fd_r, fd_g, fd_b, idx;
	always @(posedge xclk or negedge rst_n) begin
		if (!rst_n) begin
			fd_r  = $fopen(FILE0, "wb");
            fd_g  = $fopen(FILE1, "wb");
            fd_b  = $fopen(FILE2, "wb");
            idx   = 0;
            //$display("idx222 = %0d", idx);
		end else if (data_en) begin
            //$display("idx = %0d", idx);
            r_buff_up  [idx + 0] = i_data_r_0 ; 
            r_buff_up  [idx + 1] = i_data_r_1 ; 
            r_buff_up  [idx + 2] = i_data_r_4 ; 
            r_buff_up  [idx + 3] = i_data_r_5 ;
            r_buff_down[idx + 0] = i_data_r_2 ; 
            r_buff_down[idx + 1] = i_data_r_3 ; 
            r_buff_down[idx + 2] = i_data_r_6 ; 
            r_buff_down[idx + 3] = i_data_r_7 ;
            
            g_buff_up  [idx + 0] = i_data_g_0 ;
            g_buff_up  [idx + 1] = i_data_g_1 ; 
            g_buff_up  [idx + 2] = i_data_g_4 ; 
            g_buff_up  [idx + 3] = i_data_g_5 ;
            g_buff_down[idx + 0] = i_data_g_2 ; 
            g_buff_down[idx + 1] = i_data_g_3 ; 
            g_buff_down[idx + 2] = i_data_g_6 ; 
            g_buff_down[idx + 3] = i_data_g_7 ;

            b_buff_up  [idx + 0] = i_data_b_0 ;
            b_buff_up  [idx + 1] = i_data_b_1 ;
            b_buff_up  [idx + 2] = i_data_b_4 ; 
            b_buff_up  [idx + 3] = i_data_b_5 ;
            b_buff_down[idx + 0] = i_data_b_2 ; 
            b_buff_down[idx + 1] = i_data_b_3 ; 
            b_buff_down[idx + 2] = i_data_b_6 ; 
            b_buff_down[idx + 3] = i_data_b_7 ;
            if (idx + 4 == WIDTH ) begin 
                idx = 0;
                // 先写上面1行 数据 [单字节]
                for (integer i = 0; i < WIDTH; i = i + 1) begin
                    $fwrite(fd_r , "%c",  r_buff_up[i]);
                    $fwrite(fd_g , "%c",  g_buff_up[i]);
                    $fwrite(fd_b , "%c",  b_buff_up[i]);
                end
                 // 再写下面1行 数据 [单字节]
                for (integer j = 0; j < WIDTH; j = j + 1) begin
                    $fwrite(fd_r , "%c",  r_buff_down[j]);
                    $fwrite(fd_g , "%c",  g_buff_down[j]);
                    $fwrite(fd_b , "%c",  b_buff_down[j]);
                end
            end else begin 
                idx = idx + 4;
            end
            //$display("idx = %0d", idx);
        end else if (done) begin
			$fflush(fd_r );
            $fflush(fd_g);
            $fflush(fd_b );
        end
	end
endmodule
