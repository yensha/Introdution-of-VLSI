module HCU(
    input               clk,
    input               rst,
    input               mode,
    input               enable,
    input   [3:0]       gridX,
    input   [3:0]       gridY,
    output  reg         lbp_ren,
    output  reg [11:0]  lbp_addr,
    input       [7:0]   lbp_rdata,

    output  reg         hist_wen_train,
    output  reg [7:0]   hist_wdata_train,
    output  reg [20:0]  hist_addr_train,
    output  reg         hist_ren_train,
    input   [7:0]       hist_rdata_train,

    output  reg         hist_wen_predict,
    output  reg [7:0]   hist_wdata_predict,
    output  reg [13:0]  hist_addr_predict,
    output  reg         hist_ren_predict,
    input   [7:0]       hist_rdata_predict,

    output  reg         done
    );

    // put your design here
reg [2:0] cs, ns;
parameter[2:0] idle = 3'd0, wait_read = 3'd1, read_lbp = 3'd2, write_lbp = 3'd3;
parameter[2:0] wait_hist = 3'd4, hist_read = 3'd5, hist_write = 3'd6, finish = 3'd7; 
reg [7:0] grid_num;// 在哪個grid
reg [7:0] picture;//which subject
//reg [7:0] pre_picture;//predicted picture
reg [14:0] initial_num;
always@(posedge clk or posedge rst)begin
    if(rst)
        cs <= idle;
    else begin
        cs <= ns;
        
    end
end

always@(*) begin
    case(cs)
        idle:begin
            if(enable)
                ns = wait_read;
            else
                ns = idle;
        end
        wait_read:begin
            ns = read_lbp;
        end
        read_lbp:begin
            if(initial_num > 15'd16383)
                ns = write_lbp;
            else 
                ns = wait_read;
        end
        write_lbp:
            ns = wait_hist;
        wait_hist:
            ns = hist_read;
        hist_read:
            ns = hist_write;
        hist_write:begin
            if(lbp_addr == 12'd4095)
                ns = finish;
            else
                ns = wait_read;
        end
        finish:
            ns = idle;
        default:
            ns = idle;
    endcase
end  

//address
always@(posedge clk or posedge rst)begin
    if(rst)begin
        lbp_addr <= 12'd0;
        hist_addr_train <= 21'd0;
        hist_addr_predict <= 14'd0;
        picture <= 8'd0;
        //pre_picture <= 8'd0;
        grid_num <= 8'd0;
        initial_num <= 15'd0;
    end
    else begin
        case(cs)
            idle:begin
                lbp_addr <= 12'd0;
                hist_addr_train <= 21'd0;
                hist_addr_predict <= 14'd0;
                grid_num <= 8'd0;
                initial_num <= 15'd0;
            end
            wait_read:begin
                lbp_addr <= lbp_addr;
                if(mode)
                    hist_addr_predict <= initial_num;
                else
                    hist_addr_train <= initial_num + 16384 * picture;
            end
            read_lbp:begin
                if(initial_num > 15'd16383)
                    lbp_addr <= lbp_addr;
                else
                    initial_num <=  initial_num + 15'd1;
            end
            write_lbp:begin
                if(mode)
                    hist_addr_predict <= 16384 * picture + 256 * grid_num + lbp_rdata;
                else 
                    hist_addr_train <= 16384 * picture + 256 * grid_num + lbp_rdata;
            end
            wait_hist:
                lbp_addr <= lbp_addr;
            hist_read:
                lbp_addr <= lbp_addr;
            hist_write:begin
                if(lbp_addr[2:0] == 3'd7)begin
                    lbp_addr <= lbp_addr + 12'd57;
                    if(lbp_addr == 12'd4095)
                        picture <= picture + 8'd1;
                    else if(lbp_addr[8:6] == 3'd7)begin//end one grid
                        if(lbp_addr[8:0] == 9'd511)
                            lbp_addr <= lbp_addr + 12'd1;
                            
                        else begin
                            
                            lbp_addr <= lbp_addr - 12'd447;// addr - 7 * 64 + 1
                        end
                        grid_num <= grid_num + 8'd1;
                    end
                    
                end
                else
                    lbp_addr <= lbp_addr + 12'd1;

            end
            default:begin
                lbp_addr <= 12'd0;
                hist_addr_train <= 21'd0;
                hist_addr_predict <= 14'd0;
            end
        endcase
        
    end
end  
//data
always@(posedge clk or posedge rst) begin
    if(rst)begin
        hist_wdata_predict <= 8'd0;
        hist_wdata_train <= 8'd0;
    end
    else begin

        case(cs)
            idle:begin
                hist_wdata_predict <= 8'd0;
                hist_wdata_train <= 8'd0;
            end
            wait_read:begin
                if(mode)begin
                    if(initial_num > 15'd16383)
                        hist_wdata_predict <= hist_wdata_predict;
                    else
                        hist_wdata_predict <= 8'd0;
                end
                else begin
                    if(initial_num > 15'd16383)
                        hist_wdata_train <= hist_wdata_train;
                    else
                        hist_wdata_train <= 8'd0;
                end
                
            end
            read_lbp:begin
                if(mode)
                    hist_wdata_predict <= hist_wdata_predict;
                else
                    hist_wdata_train <= hist_wdata_train;
            end
            write_lbp:begin
                if(mode)
                    hist_wdata_predict <= hist_wdata_predict;
                else
                    hist_wdata_train <= hist_wdata_train;
            end
            wait_hist:begin
                if(mode)
                    hist_wdata_predict <= hist_wdata_predict;
                else
                    hist_wdata_train <= hist_wdata_train;
            end
            hist_read:begin
                if(mode)begin
                    
                    hist_wdata_predict <= hist_rdata_predict + 21'd1 ;
                
                end
                else begin
                    hist_wdata_train <= hist_rdata_train + 14'd1;
                    
                end
            end
            hist_write:begin
                if(mode)
                    hist_wdata_predict <= hist_wdata_predict;
                else
                    hist_wdata_train <= hist_wdata_train;
            end
            default:begin
                hist_wdata_predict <= 8'd0;
                hist_wdata_train <= 8'd0;
            end
        endcase
    end
end  

//signal
always@(posedge clk or posedge rst) begin
    if(rst)begin
        lbp_ren <= 1'd0;
        hist_wen_predict <= 1'd0;
        hist_ren_predict <= 1'd0;
        hist_wen_train <= 1'd0;
        hist_ren_train <= 1'd0;
        done <= 1'd0; 

    end
    else begin

        case(cs)
            idle:begin
                lbp_ren <= 1'd0;
                hist_wen_predict <= 1'd0;
                hist_ren_predict <= 1'd0;
                hist_wen_train <= 1'd0;
                hist_ren_train <= 1'd0;
                done <= 1'd0; 
            end
            wait_read:begin
                
                if(initial_num > 15'd16383)
                    lbp_ren <= 1'd0;
                else begin
                    if(mode)
                        hist_wen_predict <= 1'd1;
                    else
                        hist_wen_train <= 1'd1;
                end
            end
            read_lbp:begin
                if(initial_num > 15'd16383)
                    lbp_ren <= 1'd1;
                else begin
                    if(mode)
                        hist_wen_train <= 1'd0;
                    else
                        hist_wen_predict <= 1'd0;
                end
            end
            write_lbp:begin
                lbp_ren <= 1'd0;
                if(mode)
                    hist_ren_predict <= 1'd0;
                else
                    hist_ren_train <= 1'd0;
            end
            wait_hist:begin
                if(mode)
                    hist_ren_predict <= 1'd1;
                else
                    hist_ren_train <= 1'd1;
            end
            hist_read:begin
                if(mode)begin
                    hist_wen_predict <= 1'd1;
                    hist_ren_predict <= 1'd0;
                end
                else begin
                    hist_wen_train <= 1'd1;
                    hist_ren_train <= 1'd0;
                end
            end
            hist_write:begin
                if(lbp_addr == 12'd4095)
                    done <= 1'd1;
                else begin
                    if(mode)
                        hist_wen_predict <= 1'd0;
                    //hist_ren_predict <= 1'd0;
                    else
                        hist_wen_train <= 1'd0;
                    //hist_ren_train <= 1'd0;
                end
            end
            finish:begin
                if(mode)
                    hist_wen_predict <= 1'd0;
                else
                    hist_wen_train <= 1'd0;
                done <= 1'd0;
            end
            default:begin
                lbp_ren <= 1'd0;
                hist_wen_predict <= 1'd0;
                hist_ren_predict <= 1'd0;
                hist_wen_train <= 1'd0;
                hist_ren_train <= 1'd0;
                done <= 1'd0; 
            end
                
        endcase
    end
end  


endmodule