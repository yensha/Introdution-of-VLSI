module DCU(
    input               clk,
    input               rst,
    input               enable,
    input   [20:0]      hist_addr_offset,

    output  reg [20:0]  hist_addr_train,
    output  reg         hist_ren_train,
    input   [7:0]       hist_rdata_train,

    output  reg [13:0]  hist_addr_predict,
    output  reg         hist_ren_predict,
    input   [7:0]       hist_rdata_predict,

    output  reg [17:0]  distance,
    output  reg         valid
);
    // put your design here
parameter [2:0] idle = 3'd0, search = 3'd1, comp = 3'd2, update = 3'd3, finish = 3'd4 ;
reg [2:0] cs, ns;
always@(posedge clk or posedge rst)begin
    if(rst)
        cs <= idle;
    else 
        cs <= ns;
end

always@(*)begin
    case(cs)
        idle:begin
            if(enable)
                ns = search;
            else
                ns = idle;
        end
        search:begin
            ns = comp;
        end
        comp:begin
            ns = update;
        end
        update:begin
            if(hist_addr_predict == 14'd16383)
                ns = finish;
            else
                ns = search;
        end
        finish:begin
            ns = idle;
		end
		default:
			ns = idle;
		
    endcase
end

//signal
always@(posedge clk or posedge rst)begin
    if(rst)begin
        hist_ren_predict <= 1'd0;
        hist_ren_train <= 1'd0;
        valid <= 1'd0;
    end
    else begin
        case(cs)
            idle:begin
                hist_ren_predict <= 1'd0;
                hist_ren_train <= 1'd0;
                valid <= 1'd0;
            end
            search:begin
                hist_ren_predict <= 1'd1;
                hist_ren_train <= 1'd1;
                valid <= 1'd0;
            end
            comp:begin
            end
            update:begin
                hist_ren_predict <= 1'd0;
                hist_ren_train <= 1'd0;
                if(hist_addr_predict == 14'd16383)
                    valid <= 1'd1;
                else
                    valid <= 1'd0;
            end
            finish:begin
                valid <= 1'd0;
            end
        endcase
    end
end

//data
always@(posedge clk or posedge rst)begin
    if(rst)begin
        hist_addr_train <= 21'd0;
        hist_addr_predict <= 14'd0;
        distance <= 18'd0;
    end
    else begin
        case(cs)
            idle:begin
                hist_addr_train <= hist_addr_offset;
                hist_addr_predict <= 14'd0;
                distance <= 18'd0;
            end
            search:begin
                //distance <= distance;
            end
            comp:begin
                distance <= distance + (hist_rdata_predict - hist_rdata_train) * (hist_rdata_predict - hist_rdata_train);
            end
            update:begin
                distance <= distance;
                hist_addr_predict <= hist_addr_predict + 14'd1;
                hist_addr_train <= hist_addr_train + 21'd1;
            end
            finish:begin
            end
        endcase
    end
end



endmodule   