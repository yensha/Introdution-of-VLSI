module Comparator(
    input                   clk,
    input                   rst,
    input                   enable,
    input   [7:0]           histcount,
    input                   dcu_valid,
    input   [17:0]          distance,
    input   [4:0]           id,

    output  reg             id_ren,
    output  reg [7:0]       id_counter,
    output  reg             dcu_enable,
    output  reg [4:0]       label,
    output  reg [17:0]      minDistance,
    output  reg [20:0]      hist_addr_offset,
    output  reg             done
);

parameter [2:0] idle = 3'd0,  dcu_start = 3'd1, dcu_end = 3'd2, finish =3'd3;
reg [2:0] ns, cs;
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
                ns = dcu_start;
            else
                ns = idle;
        end
        dcu_start:begin
            if(dcu_valid)
                ns = dcu_end;
            else 
                ns = dcu_start;
        end
        dcu_end:begin
            if(id_counter == histcount)// compare to the last picture in train 
                ns = finish;
            else 
                ns = dcu_start;
        end
        finish:
            ns = idle;
		default:
			ns = idle;
    endcase
end

//signal
always@(posedge clk or posedge rst)begin
    if(rst)begin
        dcu_enable <= 1'd0;
        done <= 1'd0;
        id_ren <= 1'd0;
    end
    else begin
        case(cs)
            idle:begin
                done <= 1'd0;
                if(enable)
                    dcu_enable <= 1'd1;
                else
                    dcu_enable <= 1'd0;
            end
            dcu_start:begin
                if(dcu_valid)
                    id_ren <= 1'd1;
                dcu_enable <= 1'd0;
            end
            dcu_end:begin
                dcu_enable <= 1'd1;
                id_ren  <= 1'd0;
                if(id_counter == histcount)
                    done <= 1'd1;
            end
            finish:
                done <= 1'd0;
        endcase
    end
end
//value
always@(posedge clk or posedge rst)begin
    if(rst) begin
        id_counter <= 8'd0;
        label <= 5'd0;
        minDistance <= 18'd0;
        hist_addr_offset <= 21'd0;
    end
    else
        case(cs)
            idle:begin
                id_counter <= 8'd0;
                //label <= 5'd0;
                
                minDistance <= 18'd262143;
                hist_addr_offset <= 21'd0;
            end
            dcu_start:begin
                if(dcu_valid)
                    hist_addr_offset <= hist_addr_offset + 21'd16384;

            end
            dcu_end:begin
                if(distance < minDistance)begin
                    minDistance <= distance;
                    label <= id;
                end
                id_counter <= id_counter + 8'd1;
                
            end
            finish:begin
                
            end
        endcase
end

endmodule