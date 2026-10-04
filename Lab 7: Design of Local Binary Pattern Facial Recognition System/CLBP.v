module CLBP
#(
    parameter INT_WIDTH     = 9,
    parameter FRAC_WIDTH    = 16
)
(
    input                                       clk,
    input                                       rst,
    input                                       enable,
    output reg  [11:0]                          gray_addr,
    output reg                                  gray_OE,
    input       [7:0]                           gray_data,
    output reg  [11:0]                          lbp_addr,
    output reg                                  lbp_WEN,
    output reg  [7:0]                           lbp_data,
    output reg  [(INT_WIDTH+FRAC_WIDTH)-1:0]    theta, // in radian
    output reg                                  theta_valid,
    input       [(INT_WIDTH+FRAC_WIDTH)-1:0]    cos_data,
    input                                       cos_valid,
    input       [(INT_WIDTH+FRAC_WIDTH)-1:0]    sin_data,
    input                                       sin_valid,
    output reg                                  finish
    );  
	
    // put your design here
reg [2:0] cs, ns;
parameter[2:0] idle = 3'd0, write = 3'd1, read = 3'd2, get = 3'd3, compute = 3'd4, done = 3'd5;
reg [3:0] counter;
reg [2:0] s_counter;
reg [7:0] mid_value;
reg [7:0] f00_value, f01_value, f10_value, f11_value;
reg [23:0] sum_value;
parameter [24:0] pi = 25'b0000000110010010000111111, one = 25'b0000000010000000000000000, closer = 25'b0000000001111111111111111, three = 25'b0000000110000000000000000;
wire [24:0] angle;
wire [49:0] rx, ry;
wire [24:0] tx, ty, rx25, ry25;
wire [24:0] x_1, x_2, y_1, y_2;
wire [49:0] w1, w2, w3, w4;
wire [23:0] high1, high2;
wire [11:0] width1, width2;
reg [11:0] f00, f01, f10, f11;
wire [32:0] sum;


always@(posedge clk or posedge rst)begin
    if(rst)
        cs <= idle;
    else begin
        cs <= ns;
        
    end
end
//counters
always@(posedge clk or posedge rst)begin
    if(rst) begin
        counter <= 4'd0;
        s_counter <= 3'd0;
    end
    else begin
        case(cs)
            idle: begin
                counter <= 4'd0;
                s_counter <= 3'd0;
            end
            write:begin
                if(counter == 4'd8)
                    counter <= 4'd0;
                else
                    counter <= counter;
                s_counter <= 3'd0;
            end
            read:begin 
                counter <= counter;
                s_counter <= s_counter;
            end
            get:begin
                counter <= counter;
                if(s_counter == 3'd6)
                    s_counter <= s_counter;
                else
                    s_counter <= s_counter + 3'd1;
            end
            compute:begin
                s_counter <= s_counter;
                
                counter <= counter + 4'd1;
            end
            done:begin
                counter <= counter;
                s_counter <= s_counter;
            end
            default:begin
                counter <= 4'd0;
                s_counter <= 3'd0;
            end
        endcase
    end
end

//state
always@(*)begin
    case(cs)
        idle: begin
           if(enable)
                ns = write;
            else
                ns = idle;
        end
        write: begin
            if(lbp_addr >= 12'd4095)
                    ns = done;
            else if(lbp_addr < 12'd191 || lbp_addr > 12'd3903 || lbp_addr[5:0] > 6'd60 || lbp_addr[5:0] < 6'd3)
                ns = write;
            else if(counter == 4'd8)begin
                ns = write;
            end
            else 
                ns = read;
        end
        read:
            ns = get;
        get: begin
            if(s_counter == 3'd6)
                ns = compute;
            else
                ns = read;
        end
        compute:begin
            ns = write;
        end
        done: begin
            ns = idle;
        end
        default:
            ns = idle;
    endcase
end

// address
always@(posedge clk or  posedge rst)begin
    if(rst) begin
        gray_addr <= 12'd0;
        lbp_addr <= 12'd0;
    end
    else begin
        case(cs)
            idle: begin
                gray_addr <= 12'd0;
                lbp_addr <= 12'd0;
            end
            write: begin
                if(lbp_addr >= 12'd4095)
                    lbp_addr <= lbp_addr;
                else if(counter == 4'd8)begin
                    lbp_addr <= lbp_addr + 12'd1;
                    gray_addr <= lbp_addr + 12'd1;
                end
                else if(lbp_addr < 12'd191 || lbp_addr > 12'd3903 || lbp_addr[5:0] > 6'd60 || lbp_addr[5:0] < 6'd3)
                    lbp_addr <= lbp_addr + 12'd1;
                else begin
                    lbp_addr <= lbp_addr;
                    gray_addr <= lbp_addr;
                end
            end
            read: begin
                lbp_addr <= lbp_addr;//address change   
                gray_addr <= gray_addr;
            end
            get: begin
                lbp_addr <= lbp_addr;
                
				if(s_counter == 3'd0)
					gray_addr <= gray_addr;
				else if(s_counter == 3'd1)begin
					gray_addr <= f00;
				end
				else if(s_counter == 3'd2)begin
					gray_addr <= f01;
				end
				else if(s_counter == 3'd3) begin
					gray_addr <= f10;
				end
				else if(s_counter == 3'd4)
					gray_addr <= f11;
				else
					gray_addr <= gray_addr;
            end
            compute: begin
                lbp_addr <= lbp_addr;
                gray_addr <= gray_addr;
            end
            done:begin
                lbp_addr <= lbp_addr;
                gray_addr <= gray_addr;
            end

            default: begin
                gray_addr <= 12'd0;
                lbp_addr <= 12'd0;
            end
        endcase
    end
end 

//signal
always@(posedge clk or posedge rst)begin
    if(rst) begin
        gray_OE <= 1'd0;
        lbp_WEN <= 1'd0;
        finish <= 1'd0;
        theta_valid <= 1'd0;
    end
    else begin
        case(cs)
            idle: begin
                if(enable)begin
                    lbp_WEN <= 1'd1;
                    gray_OE <= 1'd0;
                    finish <= 1'd0;
                    theta_valid <= 1'd0;
                end
                else begin
                    gray_OE <= 1'd0;
                    lbp_WEN <= 1'd0;
                    finish <= 1'd0;
                    theta_valid <= 1'd0;
                end
            end
            write: begin
                if(lbp_addr == 12'd4095)
                        finish <= 1'd1;
                else if(lbp_addr < 12'd191 || lbp_addr > 12'd3903 || lbp_addr[5:0] >= 6'd60 || lbp_addr[5:0] < 6'd3)
                    lbp_WEN <= 1'd1;
                else begin
                    gray_OE <= 1'd1;
                    theta_valid <= 1'd1;
                    lbp_WEN <= 1'd0;
                end
            end
            read: begin
                    gray_OE <= gray_OE;
                    theta_valid <= theta_valid;
                end
            get:begin

                gray_OE <= gray_OE;
                theta_valid <= theta_valid;
            end
            compute:begin
                    gray_OE <= gray_OE;
                    if(s_counter == 3'd6)begin
                        lbp_WEN <= 1'd1;
                    end
                    else 
                        lbp_WEN <= 1'd0;
                end
            done: begin
                finish <= 1'd0;
			end
        endcase
    end
end
//data
assign angle = (pi * counter)/4;
assign rx = 25'd3*cos_data;
assign rx25 = (cos_data == -closer)?-three:(cos_data == closer)?three:{rx[24:0]};

assign ry = -25'd3*sin_data;
assign ry25 = (sin_data == closer)?-three:(sin_data == -closer)?three:{ry[24:0]};
assign x_1 = {rx25[24:16], 16'd0}; //fixed point
assign x_2 = (rx25[15:0] == 16'd0)?x_1:({rx25[24:16], 16'd0} + one);
assign y_1 = {ry25[24:16], 16'd0};
assign y_2 = (ry25[15:0] == 16'd0)?y_1:({ry25[24:16], 16'd0} + one); 
assign tx = rx25 - x_1; //fixed point
assign ty = ry25 - y_1;
assign w1 = (one - tx)*(one - ty); // 50 bit, point between index 25 26
assign w2 = tx*(one - ty);
assign w3 = ty*(one - tx);
assign w4 = ty*tx;
//解決gray_address的問題
assign high1 = $signed(12'd64 * y_1[24:16]);
assign high2 = $signed(12'd64 * y_2[24:16]);
assign width1 = $signed(x_1[24:16]);
assign width2 = $signed(x_2[24:16]);
// assign f00 = lbp_addr + width1 + high1[11:0]; // 12 bit
// assign f01 = lbp_addr + width1 + high2[11:0];
// assign f10 = lbp_addr + width2 + high1[11:0];
// assign f11 = lbp_addr + width2 + high2[11:0];
assign sum = f00_value * {w1[40:16]} + f01_value * {w2[40:16]}  + f10_value * {w3[40:16]} + f11_value * {w4[40:16]};

//value and theta
always@(posedge clk or posedge rst)begin
    if(rst)
        mid_value <= 8'd0;
	else begin
	    case(cs)
	        idle:begin 
	            mid_value <= 8'd0;
	            f00 <= 12'd0;
	            f01 <= 12'd0;
	            f10 <= 12'd0;
	            f11 <= 12'd0;
	        end
	        write:begin
	            theta <= angle;
	            
	            
	        end
	        read:begin
	            
	            theta <= angle;
	        end
	        get: begin
	            if(!(counter || s_counter))
	                mid_value <= gray_data;//gray_address change
	
	            if(s_counter == 3'd0)
	                f00 <= lbp_addr + width1 + high1[11:0];
	            else if(s_counter == 3'd1)begin
	                f01 <= lbp_addr + width1 + high2[11:0];
	                
	            end
	            else if(s_counter == 3'd2)begin
	                f10 <= lbp_addr + width2 + high1[11:0];
	                
	            end
	            else if(s_counter == 3'd3) begin
	                f11 <= lbp_addr + width2 + high2[11:0];
	                
	            end
	            
	                
	        end     
	        compute:begin
	            theta <= angle;
	        end
	        done:begin 
	            theta <= 25'd0;
	        end
	        default:
	            theta <= 25'd0;
		endcase
	end
	
end


// lbp data
always@(posedge clk or posedge rst)begin
    if(rst)begin
        lbp_data <= 8'd0;
        f00_value <= 8'd0;
        f01_value <= 8'd0;
        f10_value <= 8'd0;
        f11_value <= 8'd0;
        sum_value <= 33'd0;
    end
    else begin
        case(cs)
            idle: begin
                lbp_data <= 8'd0;
                f00_value <= 8'd0;
                f01_value <= 8'd0;
                f10_value <= 8'd0;
                f11_value <= 8'd0;
                sum_value <= 33'd0;
            end
            write:begin
                if(lbp_addr < 12'd191 || lbp_addr > 12'd3903 || lbp_addr[5:0] > 6'd60 || lbp_addr[5:0] < 6'd3)
                    lbp_data <= 8'd0;
                else begin
                    if(counter == 4'd8)
                        lbp_data <= 8'd0;
                    else
                        lbp_data <= lbp_data;
                    f00_value <= 8'd0;
                    f01_value <= 8'd0;
                    f10_value <= 8'd0;
                    f11_value <= 8'd0;
                end
            end
            read:begin
                lbp_data <= lbp_data;
            end
            get:begin
                if(s_counter == 3'd2)
                    f00_value <= gray_data;
                else if(s_counter == 3'd3)
                    f01_value <= gray_data;
                else if(s_counter == 3'd4)
                    f10_value <= gray_data;
                else if(s_counter == 3'd5)
                    f11_value <= gray_data;
                else if(s_counter == 3'd6)
                    sum_value <= sum;
            end     
            compute: begin
                if(sum_value[15])begin
                    if((sum_value[23:16] + 8'd1 )>= mid_value)
                        lbp_data[counter] <= 8'd1;
                end
                else begin
                    if(sum_value[23:16] >= mid_value)
                        lbp_data[counter] <= 8'd1;
                end
            end
            done:
                lbp_data <= 8'd0;
            default:
                lbp_data <= lbp_data;
        endcase
    end
end

endmodule