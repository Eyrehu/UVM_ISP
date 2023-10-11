/*
 * ISP - 反马赛克(Demosaic)处理 
   image sensor处理后的 bayer类型图像转为  -> R, Gr, Gb, B 图像
 */

module isp_demosaic #(
	parameter BITS          = 8, //支持8/16/24/32
	parameter H_frontporch  = 50,
	parameter H_PULSE       = 1,
	parameter H_backporch   = 50,
	parameter HEIGHT        = 512,
	parameter V_frontporch  = 10,
	parameter V_PULSE       = 1,
	parameter V_backporch   = 10,
	parameter WIDTH         = 768,
    parameter h_chan        = 4,
    parameter v_chan        = 2,
    parameter BAYER         = "rggb"
)(
    input                   xclk      ,
    input                   rst_n     ,
    input                   i_data_en ,
    input                   i_phsync  ,
    input                   i_pvsync  ,
    input   [BITS-1:0]      i_data_0  ,
    input   [BITS-1:0]      i_data_1  ,
    input   [BITS-1:0]      i_data_2  ,
    input   [BITS-1:0]      i_data_3  ,
    input   [BITS-1:0]      i_data_4  ,
    input   [BITS-1:0]      i_data_5  ,
    input   [BITS-1:0]      i_data_6  ,
    input   [BITS-1:0]      i_data_7  ,

    output                  o_data_en ,
    output                  o_phsync  ,
    output                  o_pvsync  ,

    output   [BITS-1:0]     o_data_r_0  , o_data_g_0 ,  o_data_b_0 ,
    output   [BITS-1:0]     o_data_r_1  , o_data_g_1 ,  o_data_b_1 ,
    output   [BITS-1:0]     o_data_r_2  , o_data_g_2 ,  o_data_b_2 ,
    output   [BITS-1:0]     o_data_r_3  , o_data_g_3 ,  o_data_b_3 ,
    output   [BITS-1:0]     o_data_r_4  , o_data_g_4 ,  o_data_b_4 ,
    output   [BITS-1:0]     o_data_r_5  , o_data_g_5 ,  o_data_b_5 ,
    output   [BITS-1:0]     o_data_r_6  , o_data_g_6 ,  o_data_b_6 ,
    output   [BITS-1:0]     o_data_r_7  , o_data_g_7 ,  o_data_b_7 ,

    output                  done       );


    localparam H_transfercycle = WIDTH  / h_chan;
    localparam V_transferline  = HEIGHT / v_chan;
	localparam H_totalcycle    = H_frontporch + H_PULSE + H_transfercycle + H_backporch ;
	localparam V_totalline     = V_frontporch + V_PULSE + V_transferline  + V_backporch ;

    localparam integer H_bit   = clogb2(HEIGHT-1);
    localparam integer V_bit   = clogb2(WIDTH -1);
    localparam integer num3    = clogb2(H_totalcycle -1);


    // 延迟1行linedelay + DLY_CLK 个cycles
    // 这种延迟方式太太太浪费资源了，需要使用新的方式来实现
    localparam DLY_CLK = H_totalcycle + 2;
    
    reg        [H_totalcycle-1:0] data_en_tmp_dly;
    reg        [DLY_CLK     -1:0]     data_en_dly;
    reg        [DLY_CLK     -1:0]      pvsync_dly;
    reg        [DLY_CLK     -1:0]      phsync_dly;
    
    always @ (posedge xclk or negedge rst_n) begin
        if (!rst_n) begin
            data_en_tmp_dly <= 0;
            data_en_dly     <= 0;
            pvsync_dly       <= 0;
            phsync_dly       <= 0;
        end else begin
            data_en_tmp_dly <= {data_en_tmp_dly[H_totalcycle-2:0], i_data_en};
            data_en_dly     <= {data_en_dly    [DLY_CLK     -2:0], i_data_en};
            pvsync_dly      <= { pvsync_dly    [DLY_CLK     -2:0], i_pvsync };
            phsync_dly      <= { phsync_dly    [DLY_CLK     -2:0], i_phsync };
        end
    end

    // 处理 o_data_en，存在 "1"行 的line_delay , 且要延迟i_data_en 1个cycle
    assign o_data_en   = data_en_dly[DLY_CLK-1];
    assign o_pvsync    =  pvsync_dly[DLY_CLK-1];
    assign o_phsync    =  phsync_dly[DLY_CLK-1];
    
    wire   data_en_tmp = data_en_tmp_dly[H_totalcycle-1];


    // 处理列数: col_cnt;  // 0, 1, 2, 3, ..., WIDTH/v_chan-1.  当前列数，根据i_data_en的上升沿开始计数，xclk上升沿且i_data_en为高，则加1
    reg [V_bit:0] col_cnt; 
    always @ (posedge xclk or negedge rst_n) begin
        if (!rst_n) begin
            col_cnt <= {V_bit{1'b0}};
        end else if ( i_pvsync ) begin
            col_cnt <= {V_bit{1'b0}};
        end else if (i_data_en | data_en_tmp) begin 
            col_cnt <= col_cnt + 1; 
        end else 
            col_cnt <= 0;
    end

    // 处理行数: 0, 1, 2, 3, ..., HEIGHT/h_chan - 1；只考虑visiable区域
    reg  [H_bit:0] line_cnt ;
    always @ (posedge xclk or negedge rst_n) begin
        if (!rst_n) begin
            line_cnt <= {H_bit{1'b0}};
        end else if ( i_pvsync ) begin
            line_cnt <= {H_bit{1'b0}};
        end else if(col_cnt == WIDTH/h_chan) begin 
            line_cnt <= line_cnt + 1;
        end else 
            line_cnt <= line_cnt;
    end



    //wire [H_bit:0]  row_cnt = (i_data_en) ? line_cnt : {H_bit{1'bx}} ;
    wire [H_bit:0]  row_cnt = (col_cnt != WIDTH/h_chan) ? (i_data_en | data_en_tmp) ? line_cnt : {H_bit{1'bx}} : line_cnt ;
    

    reg [H_bit : 0]  line_nums;
    reg              delay;
    reg              done_tmp;
    always @ (posedge xclk or negedge rst_n) begin
        if (!rst_n) begin
            line_nums = 0;
            done_tmp <= 0;
        end else begin
            delay <= data_en_dly[DLY_CLK-1];  
            if (delay & !data_en_dly[DLY_CLK-1]) begin
                line_nums  = line_nums + 1;
            end
            if (line_nums == HEIGHT/v_chan)  begin 
                done_tmp <= 1;
                line_nums = 0;
            end else begin
                done_tmp <= 0;
            end   
        end
    end
    assign done = done_tmp;


// 定义3个memory，
    reg [BITS-1:0] mem_top_pre [WIDTH]; //        前1行中的上面1行
    reg [BITS-1:0] mem_down_pre[WIDTH]; //        前1行中的下面1行
    reg [BITS-1:0] mem_pre_pre [WIDTH]; // 前1行的前1行中的下面1行
        
    reg [BITS-1:0] pix00, pix01, pix02, pix03, pix04, pix05;
    reg [BITS-1:0] pix10, pix11, pix12, pix13, pix14, pix15;
    reg [BITS-1:0] pix20, pix21, pix22, pix23, pix24, pix25;
    reg [BITS-1:0] pix30, pix31, pix32, pix33, pix34, pix35;
    
    // i_data_en = 1 ==> col_cnt = 0, 1, 2, ...,  WIDTH/h_chan - 1;
    // [1] 边界处理：第0行不会参与计算，只是向memory中存储新的数据
    always @ (posedge xclk or negedge rst_n) begin
        if (!rst_n) begin
            for(integer i = 0; i < WIDTH; i++) begin 
                mem_top_pre[i]  <= 0;
                mem_pre_pre[i]  <= 0;
                mem_down_pre[i] <= 0;  
            end
        end else if ((i_data_en) && (row_cnt == 0)) begin 
        // 两个memory解决不了，需要三个
            mem_top_pre [h_chan * col_cnt + 0] <= i_data_0;
            mem_top_pre [h_chan * col_cnt + 1] <= i_data_1;
            mem_top_pre [h_chan * col_cnt + 2] <= i_data_4;
            mem_top_pre [h_chan * col_cnt + 3] <= i_data_5;

            mem_pre_pre [h_chan * col_cnt + 0] <= i_data_2;
            mem_pre_pre [h_chan * col_cnt + 1] <= i_data_3;
            mem_pre_pre [h_chan * col_cnt + 2] <= i_data_6;
            mem_pre_pre [h_chan * col_cnt + 3] <= i_data_7;
            
            mem_down_pre[h_chan * col_cnt + 0] <= i_data_2;
            mem_down_pre[h_chan * col_cnt + 1] <= i_data_3;
            mem_down_pre[h_chan * col_cnt + 2] <= i_data_6;
            mem_down_pre[h_chan * col_cnt + 3] <= i_data_7;
        end
    end
    
    always @ (posedge xclk or negedge rst_n) begin
        if (!rst_n) begin

        end else begin 
            if ((row_cnt > 0 ) && (row_cnt < HEIGHT/v_chan ) )begin 
            // [2] 非边界处理：先从memory中取上面2行第数据 然后再向memory中存储新的数据
                if (col_cnt < WIDTH/h_chan  )  begin
                    pix11 <= mem_top_pre [h_chan *  col_cnt + 0 ] ;
                    pix12 <= mem_top_pre [h_chan *  col_cnt + 1 ] ;
                    pix13 <= mem_top_pre [h_chan *  col_cnt + 2 ] ;
                    pix14 <= mem_top_pre [h_chan *  col_cnt + 3 ] ;
                                                    
                    pix21 <= mem_down_pre[h_chan *  col_cnt + 0 ] ;
                    pix22 <= mem_down_pre[h_chan *  col_cnt + 1 ] ;
                    pix23 <= mem_down_pre[h_chan *  col_cnt + 2 ] ;
                    pix24 <= mem_down_pre[h_chan *  col_cnt + 3 ] ;

                    pix31 <= i_data_0;
                    pix32 <= i_data_1;
                    pix33 <= i_data_4;
                    pix34 <= i_data_5;
                    if (row_cnt == 1 ) begin 
/************************准备数据用于处理第0行 [syncrt]*******************/

                        pix01 <= mem_down_pre[h_chan * col_cnt + 0 ] ; // pix21
                        pix02 <= mem_down_pre[h_chan * col_cnt + 1 ] ; // pix23
                        pix03 <= mem_down_pre[h_chan * col_cnt + 2 ] ; // pix24
                        pix04 <= mem_down_pre[h_chan * col_cnt + 3 ] ; // pix24
                            
                        // 左边界 + 上边界 处理，做镜像。
                        if ( col_cnt == 0 ) begin 

                            pix00 <= mem_down_pre[h_chan * col_cnt + 1 ] ; // pix22
                            pix05 <= mem_down_pre[h_chan * col_cnt + 4 ] ; // 
                            
                            pix10 <= mem_top_pre [h_chan * col_cnt + 1 ] ; // pix12
                            pix15 <= mem_top_pre [h_chan * col_cnt + 4 ] ; // 
                        
                            pix20 <= mem_down_pre[h_chan * col_cnt + 1 ] ; // pix22
                            pix25 <= mem_down_pre[h_chan * col_cnt + 4 ] ; // 
                            
                            pix30 <= i_data_1                           ; // pix22
                            // 差一个 pix35， 没办法
                        
                        end else if ((col_cnt > 0) && (col_cnt < WIDTH/h_chan - 1)) begin
                        // 上边界 处理，做镜像。
                
                            pix00 <= pix04; //pix24   ; 
                            pix05 <= mem_down_pre[h_chan * col_cnt + 4 ] ;
                        
                            pix10 <= pix14   ;  // 相对于 mem_top_pre  [h_chan *  col_cnt + 2 ] ; 延迟2 cycle
                            pix15 <= mem_top_pre  [h_chan * col_cnt + 4 ] ;
                            
                            pix20 <= pix24   ;  // 相对于 mem_down_pre[h_chan *  col_cnt + 2 ] ; 延迟2 cycle 
                            pix25 <= mem_down_pre[h_chan * col_cnt + 4 ] ;
                            
                            pix30 <= pix34   ; 
                             // 差一个 pix35， 没办法
                        end else if (col_cnt == WIDTH/h_chan - 1) begin
                        // 右边界 处理，做镜像。考虑到右侧边界情况：最后一列时 col_cnt + 4 则会越界、取值是错误的。

                            pix00 <= pix04    ; 
                            pix05 <= mem_down_pre[h_chan * col_cnt + 2 ];

                            pix10 <= pix14    ; // pix12
                            pix15 <= mem_top_pre [h_chan * col_cnt + 2 ];
                        
                            pix20 <= pix24    ; 
                            pix25 <= mem_down_pre[h_chan * col_cnt + 2 ];
                            
                            pix30 <= pix34    ;
                            pix35 <= i_data_4 ;  // 此时 i_data_en为0，不会有输入数据了，故需要提前暂存一个数据
                        end
/************************准备数据用于处理第0行 [Over]*******************/

                    end else if (row_cnt != HEIGHT/v_chan ) begin
                        pix01 <= mem_pre_pre [h_chan * col_cnt + 0 ] ;
                        pix02 <= mem_pre_pre [h_chan * col_cnt + 1 ] ;
                        pix03 <= mem_pre_pre [h_chan * col_cnt + 2 ] ;
                        pix04 <= mem_pre_pre [h_chan * col_cnt + 3 ] ;
/************************准备数据用于处理第1--HEIGHT/v_chan - 1s行 [syncrt]*******************/
                        if ( col_cnt == 0 ) begin 

                            pix00 <= mem_pre_pre [h_chan * col_cnt + 1 ] ;
                            pix05 <= mem_pre_pre [h_chan * col_cnt + 4 ] ;

                            pix10 <= mem_top_pre [h_chan * col_cnt + 1 ] ; // pix12
                            pix15 <= mem_top_pre [h_chan * col_cnt + 4 ] ; // 

                            pix20 <= mem_down_pre[h_chan * col_cnt + 1 ] ; // pix22
                            pix25 <= mem_down_pre[h_chan * col_cnt + 4 ] ; // 
                            
                            pix30 <= i_data_1                            ; // pix22
                            // 差一个 pix35， 没办法
                        end else if ((col_cnt > 0) && (col_cnt < WIDTH/h_chan - 1)) begin 

                            pix00 <= pix04 ;
                            pix05 <= mem_pre_pre [h_chan * col_cnt + 4 ] ;

                            pix10 <= pix14; // 理论上是 mem_top_pre [h_chan * col_cnt - 1], 但是数据已经被覆盖掉了
                            pix15 <= mem_top_pre [h_chan * col_cnt + 4 ] ; // 

                            pix20 <= pix24;
                            pix25 <= mem_down_pre[h_chan * col_cnt + 4 ] ; // 
                            
                            pix30 <= pix34;
                            // 差一个 pix35， 没办法
                            
                        end else if (col_cnt == WIDTH/h_chan - 1) begin

                            pix00 <= pix04   ; 
                            pix05 <= mem_pre_pre[h_chan * col_cnt + 2 ];

                            pix10 <= pix14    ; // pix12
                            pix15 <= mem_top_pre [h_chan * col_cnt + 2 ];
                        
                            pix20 <= pix24    ; 
                            pix25 <= mem_down_pre[h_chan * col_cnt + 2 ];
                            
                            pix30 <= pix34    ;
                            pix35 <= i_data_4 ;  // 此时 i_data_en为0，不会有输入数据了，故需要提前暂存一个数据
                        end 
/************************准备数据用于处理第1--HEIGHT/v_chan - 1行 [Over]*******************/
                    end
                end
                // 存储到memory
                mem_top_pre [h_chan * col_cnt + 0] <= i_data_0;
                mem_top_pre [h_chan * col_cnt + 1] <= i_data_1;
                mem_top_pre [h_chan * col_cnt + 2] <= i_data_4;
                mem_top_pre [h_chan * col_cnt + 3] <= i_data_5;
                
                mem_down_pre[h_chan * col_cnt + 0] <= i_data_2;
                mem_down_pre[h_chan * col_cnt + 1] <= i_data_3;
                mem_down_pre[h_chan * col_cnt + 2] <= i_data_6;
                mem_down_pre[h_chan * col_cnt + 3] <= i_data_7;
                
                mem_pre_pre [h_chan * col_cnt + 0] <= mem_down_pre[h_chan * col_cnt + 0] ;
                mem_pre_pre [h_chan * col_cnt + 1] <= mem_down_pre[h_chan * col_cnt + 1] ;
                mem_pre_pre [h_chan * col_cnt + 2] <= mem_down_pre[h_chan * col_cnt + 2] ;
                mem_pre_pre [h_chan * col_cnt + 3] <= mem_down_pre[h_chan * col_cnt + 3] ;
            
            end else if (row_cnt == HEIGHT/v_chan  ) begin
/************************准备数据用于处理第 HEIGHT/v_chan - 1行(最后 1 行) [syncrt]*******************/
                
                pix11 <= mem_top_pre [h_chan * col_cnt + 0 ] ;
                pix12 <= mem_top_pre [h_chan * col_cnt + 1 ] ;
                pix13 <= mem_top_pre [h_chan * col_cnt + 2 ] ;
                pix14 <= mem_top_pre [h_chan * col_cnt + 3 ] ;

                pix21 <= mem_down_pre[h_chan * col_cnt + 0 ] ;
                pix22 <= mem_down_pre[h_chan * col_cnt + 1 ] ;
                pix23 <= mem_down_pre[h_chan * col_cnt + 2 ] ;
                pix24 <= mem_down_pre[h_chan * col_cnt + 3 ] ;

                pix31 <= mem_top_pre [h_chan * col_cnt + 0 ] ;
                pix32 <= mem_top_pre [h_chan * col_cnt + 1 ] ;
                pix33 <= mem_top_pre [h_chan * col_cnt + 2 ] ;
                pix34 <= mem_top_pre [h_chan * col_cnt + 3 ] ;
                
                
                pix01 <= mem_pre_pre [h_chan * col_cnt + 0 ] ;
                pix02 <= mem_pre_pre [h_chan * col_cnt + 1 ] ;
                pix03 <= mem_pre_pre [h_chan * col_cnt + 2 ] ;
                pix04 <= mem_pre_pre [h_chan * col_cnt + 3 ] ;
                
                    
                if ( col_cnt == 0 ) begin 
                    pix00 <= mem_pre_pre [h_chan * col_cnt + 1 ] ;
                    pix05 <= mem_pre_pre [h_chan * col_cnt + 4 ] ;
                    
                    pix10 <= mem_top_pre [h_chan * col_cnt + 1 ] ; // pix12
                    pix15 <= mem_top_pre [h_chan * col_cnt + 4 ] ; // 

                    pix20 <= mem_down_pre[h_chan * col_cnt + 1 ] ; // pix22
                    pix25 <= mem_down_pre[h_chan * col_cnt + 4 ] ; // 
                    
                    pix30 <= mem_top_pre [h_chan * col_cnt + 1 ] ; // pix22
                    pix35 <= mem_top_pre [h_chan * col_cnt + 4 ] ; // pix22
                
                end else if ((col_cnt > 0) && (col_cnt < WIDTH/h_chan - 1)) begin 
                    pix00 <= pix04 ;
                    pix05 <= mem_pre_pre [h_chan * col_cnt + 4 ] ;
                    
                    pix10 <= pix14; // 理论上是 mem_top_pre [h_chan * col_cnt - 1], 但是数据已经被覆盖掉了
                    pix15 <= mem_top_pre [h_chan * col_cnt + 4 ] ; // 

                    pix20 <= pix24;
                    pix25 <= mem_down_pre[h_chan * col_cnt + 4 ] ; // 
                    
                    pix30 <= pix34;
                    pix35 <= mem_top_pre [h_chan * col_cnt + 4 ] ; // 
                    
                end else if (col_cnt == WIDTH/h_chan - 1) begin
                    pix00 <= pix04   ; 
                    pix05 <= mem_pre_pre [h_chan * col_cnt + 2 ];

                    pix10 <= pix14    ; // pix12
                    pix15 <= mem_top_pre [h_chan * col_cnt + 2 ];
                
                    pix20 <= pix24    ; 
                    pix25 <= mem_down_pre[h_chan * col_cnt + 2 ];
                    
                    pix30 <= pix34    ;
                    pix35 <= mem_top_pre [h_chan * col_cnt + 2 ];  // 此时 i_data_en为0，不会有输入数据了，故需要提前暂存一个数据
                end 
/************************准备数据用于处理第 HEIGHT/v_chan - 1行(最后 1 行) [end]*******************/   
            end
        end
    end
    
    reg [BITS-1:0] data_ul_0, data_ur_0, data_ll_0, data_lr_0 ;
    reg [BITS-1:0] data_ul_1, data_ur_1, data_ll_1, data_lr_1 ;
    reg [BITS-1:0] data_ul_2, data_ur_2, data_ll_2, data_lr_2 ;
    reg [BITS-1:0] data_ul_3, data_ur_3, data_ll_3, data_lr_3 ;
    reg [BITS-1:0] data_ul_4, data_ur_4, data_ll_4, data_lr_4 ;
    reg [BITS-1:0] data_ul_5, data_ur_5, data_ll_5, data_lr_5 ;
    reg [BITS-1:0] data_ul_6, data_ur_6, data_ll_6, data_lr_6 ;
    reg [BITS-1:0] data_ul_7, data_ur_7, data_ll_7, data_lr_7 ;
    always @ (posedge xclk or negedge rst_n) begin
        if (!rst_n) begin
        end else begin 

            data_ul_0 <= upper_left ( pix00, pix01, pix02, pix10, pix11, pix12, pix20, pix21, pix22 , 2'b00);
            data_ur_0 <= upper_left ( pix00, pix01, pix02, pix10, pix11, pix12, pix20, pix21, pix22 , 2'b01);
            data_ll_0 <= upper_left ( pix00, pix01, pix02, pix10, pix11, pix12, pix20, pix21, pix22 , 2'b10);
            data_lr_0 <= upper_left ( pix00, pix01, pix02, pix10, pix11, pix12, pix20, pix21, pix22 , 2'b11);
             
            data_ul_1 <= upper_right( pix01, pix02, pix03, pix11, pix12, pix13, pix21, pix22, pix23 , 2'b00);
            data_ur_1 <= upper_right( pix01, pix02, pix03, pix11, pix12, pix13, pix21, pix22, pix23 , 2'b01);
            data_ll_1 <= upper_right( pix01, pix02, pix03, pix11, pix12, pix13, pix21, pix22, pix23 , 2'b10);
            data_lr_1 <= upper_right( pix01, pix02, pix03, pix11, pix12, pix13, pix21, pix22, pix23 , 2'b11);

            data_ul_2 <= lower_left ( pix10, pix11, pix12, pix20, pix21, pix22, pix30, pix31, pix32, 2'b00);
            data_ur_2 <= lower_left ( pix10, pix11, pix12, pix20, pix21, pix22, pix30, pix31, pix32, 2'b01);
            data_ll_2 <= lower_left ( pix10, pix11, pix12, pix20, pix21, pix22, pix30, pix31, pix32, 2'b10);
            data_lr_2 <= lower_left ( pix10, pix11, pix12, pix20, pix21, pix22, pix30, pix31, pix32, 2'b11);

            data_ul_3 <= lower_right( pix11, pix12, pix13, pix21, pix22, pix23, pix31, pix32, pix33, 2'b00);
            data_ur_3 <= lower_right( pix11, pix12, pix13, pix21, pix22, pix23, pix31, pix32, pix33, 2'b01);
            data_ll_3 <= lower_right( pix11, pix12, pix13, pix21, pix22, pix23, pix31, pix32, pix33, 2'b10);
            data_lr_3 <= lower_right( pix11, pix12, pix13, pix21, pix22, pix23, pix31, pix32, pix33, 2'b11);

            data_ul_4 <= upper_left ( pix02, pix03, pix04, pix12, pix13, pix14, pix22, pix23, pix24, 2'b00);
            data_ur_4 <= upper_left ( pix02, pix03, pix04, pix12, pix13, pix14, pix22, pix23, pix24, 2'b01);
            data_ll_4 <= upper_left ( pix02, pix03, pix04, pix12, pix13, pix14, pix22, pix23, pix24, 2'b10);
            data_lr_4 <= upper_left ( pix02, pix03, pix04, pix12, pix13, pix14, pix22, pix23, pix24, 2'b11);

            data_ul_5 <= upper_right( pix03, pix04, pix05, pix13, pix14, pix15, pix23, pix24, pix25, 2'b00);
            data_ur_5 <= upper_right( pix03, pix04, pix05, pix13, pix14, pix15, pix23, pix24, pix25, 2'b01);
            data_ll_5 <= upper_right( pix03, pix04, pix05, pix13, pix14, pix15, pix23, pix24, pix25, 2'b10);
            data_lr_5 <= upper_right( pix03, pix04, pix05, pix13, pix14, pix15, pix23, pix24, pix25, 2'b11);
                            
            data_ul_6 <= lower_left ( pix12, pix13, pix14, pix22, pix23, pix24, pix32, pix33, pix34, 2'b00);
            data_ur_6 <= lower_left ( pix12, pix13, pix14, pix22, pix23, pix24, pix32, pix33, pix34, 2'b01);
            data_ll_6 <= lower_left ( pix12, pix13, pix14, pix22, pix23, pix24, pix32, pix33, pix34, 2'b10);
            data_lr_6 <= lower_left ( pix12, pix13, pix14, pix22, pix23, pix24, pix32, pix33, pix34, 2'b11);
            if ((row_cnt > 0 ) && (row_cnt < HEIGHT/v_chan )) begin 
                if ((col_cnt > 0 ) && (col_cnt < WIDTH/h_chan)) begin 
                    data_ul_7 <= lower_right( pix13, pix14, pix15, pix23, pix24, pix25, pix33, pix34, i_data_0, 2'b00);
                    data_ur_7 <= lower_right( pix13, pix14, pix15, pix23, pix24, pix25, pix33, pix34, i_data_0, 2'b01);
                    data_ll_7 <= lower_right( pix13, pix14, pix15, pix23, pix24, pix25, pix33, pix34, i_data_0, 2'b10);
                    data_lr_7 <= lower_right( pix13, pix14, pix15, pix23, pix24, pix25, pix33, pix34, i_data_0, 2'b11);

                end else if ((col_cnt == WIDTH/h_chan) ) begin 
                    data_ul_7 <= lower_right( pix13, pix14, pix15, pix23, pix24, pix25, pix33, pix34, pix35   , 2'b00);
                    data_ur_7 <= lower_right( pix13, pix14, pix15, pix23, pix24, pix25, pix33, pix34, pix35   , 2'b01);
                    data_ll_7 <= lower_right( pix13, pix14, pix15, pix23, pix24, pix25, pix33, pix34, pix35   , 2'b10);
                    data_lr_7 <= lower_right( pix13, pix14, pix15, pix23, pix24, pix25, pix33, pix34, pix35   , 2'b11);
                end
            end else if (row_cnt == HEIGHT/v_chan ) begin 
                data_ul_7 <= lower_right( pix13, pix14, pix15, pix23, pix24, pix25, pix33, pix34, pix35   , 2'b00);
                data_ur_7 <= lower_right( pix13, pix14, pix15, pix23, pix24, pix25, pix33, pix34, pix35   , 2'b01);
                data_ll_7 <= lower_right( pix13, pix14, pix15, pix23, pix24, pix25, pix33, pix34, pix35   , 2'b10);
                data_lr_7 <= lower_right( pix13, pix14, pix15, pix23, pix24, pix25, pix33, pix34, pix35   , 2'b11);
            end
       
        
        end
    end
    
    reg    [BITS+1:0] data_b_0, data_b_1, data_b_2, data_b_3;
    reg    [BITS+1:0] data_b_4, data_b_5, data_b_6, data_b_7;
    always @(*) begin 
        case (BAYER) 
            "rggb", "bggr": begin 
                data_b_0 = (data_ur_0 + data_ll_0) >> 1 ;
                data_b_1 = (data_ur_1 + data_ll_1) >> 1 ;
                data_b_2 = (data_ur_2 + data_ll_2) >> 1 ;
                data_b_3 = (data_ur_3 + data_ll_3) >> 1 ;
                data_b_4 = (data_ur_4 + data_ll_4) >> 1 ;
                data_b_5 = (data_ur_5 + data_ll_5) >> 1 ;
                data_b_6 = (data_ur_6 + data_ll_6) >> 1 ;
                data_b_7 = (data_ur_7 + data_ll_7) >> 1 ;
            end   
            "gbrg", "grbg": begin 
                data_b_0 = (data_ul_0 + data_lr_0) >> 1 ;
                data_b_1 = (data_ul_1 + data_lr_1) >> 1 ;
                data_b_2 = (data_ul_2 + data_lr_2) >> 1 ;
                data_b_3 = (data_ul_3 + data_lr_3) >> 1 ;
                data_b_4 = (data_ul_4 + data_lr_4) >> 1 ;
                data_b_5 = (data_ul_5 + data_lr_5) >> 1 ;
                data_b_6 = (data_ul_6 + data_lr_6) >> 1 ;
                data_b_7 = (data_ul_7 + data_lr_7) >> 1 ;
            end
        endcase
    end
    
    
 //0:BGGR 1:GBRG 2:GRBG 3:RGGB
    assign o_data_r_0  = (o_data_en==1)?(BAYER=="rggb")?data_ul_0:(BAYER=="bggr")?data_lr_0:(BAYER=="gbrg")?data_ll_0:(BAYER=="grbg")?data_ur_0:{BITS{1'bx}}:{BITS{1'bx}}; 
    assign o_data_r_1  = (o_data_en==1)?(BAYER=="rggb")?data_ul_1:(BAYER=="bggr")?data_lr_1:(BAYER=="gbrg")?data_ll_1:(BAYER=="grbg")?data_ur_1:{BITS{1'bx}}:{BITS{1'bx}}; 
    assign o_data_r_2  = (o_data_en==1)?(BAYER=="rggb")?data_ul_2:(BAYER=="bggr")?data_lr_2:(BAYER=="gbrg")?data_ll_2:(BAYER=="grbg")?data_ur_2:{BITS{1'bx}}:{BITS{1'bx}}; 
    assign o_data_r_3  = (o_data_en==1)?(BAYER=="rggb")?data_ul_3:(BAYER=="bggr")?data_lr_3:(BAYER=="gbrg")?data_ll_3:(BAYER=="grbg")?data_ur_3:{BITS{1'bx}}:{BITS{1'bx}}; 
    assign o_data_r_4  = (o_data_en==1)?(BAYER=="rggb")?data_ul_4:(BAYER=="bggr")?data_lr_4:(BAYER=="gbrg")?data_ll_4:(BAYER=="grbg")?data_ur_4:{BITS{1'bx}}:{BITS{1'bx}}; 
    assign o_data_r_5  = (o_data_en==1)?(BAYER=="rggb")?data_ul_5:(BAYER=="bggr")?data_lr_5:(BAYER=="gbrg")?data_ll_5:(BAYER=="grbg")?data_ur_5:{BITS{1'bx}}:{BITS{1'bx}}; 
    assign o_data_r_6  = (o_data_en==1)?(BAYER=="rggb")?data_ul_6:(BAYER=="bggr")?data_lr_6:(BAYER=="gbrg")?data_ll_6:(BAYER=="grbg")?data_ur_6:{BITS{1'bx}}:{BITS{1'bx}}; 
    assign o_data_r_7  = (o_data_en==1)?(BAYER=="rggb")?data_ul_7:(BAYER=="bggr")?data_lr_7:(BAYER=="gbrg")?data_ll_7:(BAYER=="grbg")?data_ur_7:{BITS{1'bx}}:{BITS{1'bx}}; 
    
    assign o_data_b_0  = (o_data_en==1)?(BAYER=="rggb")?data_lr_0:(BAYER=="bggr")?data_ul_0:(BAYER=="gbrg")?data_ur_0:(BAYER=="grbg")?data_ll_0:{BITS{1'bx}}:{BITS{1'bx}};
    assign o_data_b_1  = (o_data_en==1)?(BAYER=="rggb")?data_lr_1:(BAYER=="bggr")?data_ul_1:(BAYER=="gbrg")?data_ur_1:(BAYER=="grbg")?data_ll_1:{BITS{1'bx}}:{BITS{1'bx}};
    assign o_data_b_2  = (o_data_en==1)?(BAYER=="rggb")?data_lr_2:(BAYER=="bggr")?data_ul_2:(BAYER=="gbrg")?data_ur_2:(BAYER=="grbg")?data_ll_2:{BITS{1'bx}}:{BITS{1'bx}};
    assign o_data_b_3  = (o_data_en==1)?(BAYER=="rggb")?data_lr_3:(BAYER=="bggr")?data_ul_3:(BAYER=="gbrg")?data_ur_3:(BAYER=="grbg")?data_ll_3:{BITS{1'bx}}:{BITS{1'bx}};
    assign o_data_b_4  = (o_data_en==1)?(BAYER=="rggb")?data_lr_4:(BAYER=="bggr")?data_ul_4:(BAYER=="gbrg")?data_ur_4:(BAYER=="grbg")?data_ll_4:{BITS{1'bx}}:{BITS{1'bx}};
    assign o_data_b_5  = (o_data_en==1)?(BAYER=="rggb")?data_lr_5:(BAYER=="bggr")?data_ul_5:(BAYER=="gbrg")?data_ur_5:(BAYER=="grbg")?data_ll_5:{BITS{1'bx}}:{BITS{1'bx}};
    assign o_data_b_6  = (o_data_en==1)?(BAYER=="rggb")?data_lr_6:(BAYER=="bggr")?data_ul_6:(BAYER=="gbrg")?data_ur_6:(BAYER=="grbg")?data_ll_6:{BITS{1'bx}}:{BITS{1'bx}};
    assign o_data_b_7  = (o_data_en==1)?(BAYER=="rggb")?data_lr_7:(BAYER=="bggr")?data_ul_7:(BAYER=="gbrg")?data_ur_7:(BAYER=="grbg")?data_ll_7:{BITS{1'bx}}:{BITS{1'bx}};
    
    assign o_data_g_0  = (o_data_en==1)? (data_b_0 > {BITS{1'b1}}) ? {BITS{1'b1}} :data_b_0[BITS-1:0] : {BITS{1'bx}}; 
    assign o_data_g_1  = (o_data_en==1)? (data_b_1 > {BITS{1'b1}}) ? {BITS{1'b1}} :data_b_1[BITS-1:0] : {BITS{1'bx}}; 
    assign o_data_g_2  = (o_data_en==1)? (data_b_2 > {BITS{1'b1}}) ? {BITS{1'b1}} :data_b_2[BITS-1:0] : {BITS{1'bx}}; 
    assign o_data_g_3  = (o_data_en==1)? (data_b_3 > {BITS{1'b1}}) ? {BITS{1'b1}} :data_b_3[BITS-1:0] : {BITS{1'bx}}; 
    assign o_data_g_4  = (o_data_en==1)? (data_b_4 > {BITS{1'b1}}) ? {BITS{1'b1}} :data_b_4[BITS-1:0] : {BITS{1'bx}}; 
    assign o_data_g_5  = (o_data_en==1)? (data_b_5 > {BITS{1'b1}}) ? {BITS{1'b1}} :data_b_5[BITS-1:0] : {BITS{1'bx}}; 
    assign o_data_g_6  = (o_data_en==1)? (data_b_6 > {BITS{1'b1}}) ? {BITS{1'b1}} :data_b_6[BITS-1:0] : {BITS{1'bx}}; 
    assign o_data_g_7  = (o_data_en==1)? (data_b_7 > {BITS{1'b1}}) ? {BITS{1'b1}} :data_b_7[BITS-1:0] : {BITS{1'bx}}; 


// 右上：upper_right 
// 左上：upper_left 
// 右下：lower_right 
// 左下：lower_left

            
function [BITS-1:0] upper_left;
    input  [BITS-1:0] data00, data01, data02, data10, data11, data12, data20, data21, data22;
    input  [     1:0] pos;
    reg    [BITS+1:0] o_data;
    begin
        case (pos)
            2'b00  : o_data =  data11;                                  // o_data_ul 
            2'b01  : o_data = (data10 + data12)>>1;                     // o_data_ur
            2'b10  : o_data = (data01 + data21)>>1;                     // o_data_ll
            2'b11  : o_data = (data00 + data20 + data02 + data22) >> 2; // o_data_lr 
            default: o_data = {BITS{1'b0}};
        endcase
        upper_left = o_data > {BITS{1'b1}} ? {BITS{1'b1}} : o_data[BITS-1:0];
    end
endfunction

function   [BITS-1:0] upper_right;
    input  [BITS-1:0] data00, data01, data02, data10, data11, data12, data20, data21, data22;
    input  [     1:0] pos;
    reg    [BITS+1:0] o_data;
    begin
        case (pos)
            2'b00  : o_data = (data10 + data12) >> 1;                  // o_data_ul 
            2'b01  : o_data =  data11;                                 // o_data_ur
            2'b10  : o_data = (data00 + data20 + data02 + data22) >> 2;// o_data_ll
            2'b11  : o_data = (data01 + data21) >> 1;                  // o_data_lr 
            default: o_data = {BITS{1'b0}};
        endcase
        upper_right = o_data > {BITS{1'b1}} ? {BITS{1'b1}} : o_data[BITS-1:0];
    end
endfunction

function [BITS-1:0] lower_left;
    input  [BITS-1:0] data00, data01, data02, data10, data11, data12, data20, data21, data22;
    input  [     1:0] pos;
    reg    [BITS+1:0] o_data;
    begin
        case (pos)
            2'b00  : o_data = (data01 + data21) >> 1;                  // o_data_ul 
            2'b01  : o_data = (data00 + data20 + data02 + data22) >> 2;// o_data_ur
            2'b10  : o_data =  data11;                                 // o_data_ll
            2'b11  : o_data = (data10 + data12) >> 1;                  // o_data_lr     
            default: o_data = {BITS{1'b0}};
        endcase
        lower_left = o_data > {BITS{1'b1}} ? {BITS{1'b1}} : o_data[BITS-1:0];
    end
endfunction

function [BITS-1:0] lower_right;
    input  [BITS-1:0] data00, data01, data02, data10, data11, data12, data20, data21, data22;
    input  [     1:0] pos;
    reg    [BITS+1:0] o_data;
    begin
        case (pos)
            2'b00  : o_data = (data00 + data20 + data02 + data22) >> 2;// o_data_ul 
            2'b01  : o_data = (data01 + data21) >> 1;                  // o_data_ur
            2'b10  : o_data = (data10 + data12) >> 1;                  // o_data_ll
            2'b11  : o_data =  data11;                                 // o_data_lr 
            default: o_data = {BITS{1'b0}};
        endcase
        lower_right = o_data > {BITS{1'b1}} ? {BITS{1'b1}} : o_data[BITS-1:0];
    end
endfunction



    function integer clogb2 (input integer bit_depth); begin                                                           
	    for(clogb2 = 0; bit_depth > 0; clogb2 = clogb2+1)                   
	        bit_depth = bit_depth >> 1;                                 
	    end                                                           
	endfunction 
endmodule
