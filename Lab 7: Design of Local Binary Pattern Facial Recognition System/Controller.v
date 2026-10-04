module Controller(
    input               clk,
    input               rst,
    input               mode,
    input               enable,
    input               valid,
    input   [4:0]       id,

    // ID RAM 
    output  reg [7:0]   id_addr,
    output  reg [4:0]   id_wdata,
    output  reg         id_wen,

    // CLBP I/O
	output	reg			lbp_enable,
	input   			lbp_finish,
	output  reg			ram_clbp,
	
    // HCU I/O
    input   [3:0]       gridX_i,     
    input   [3:0]       gridY_i,        
    output  reg         hcu_enable,
    output  reg [3:0]   gridX_o,
    output  reg [3:0]   gridY_o,  
    input               hcu_finish,      
    // Comparator I/O
    input               comparator_finish,
    output  reg         comparator_enable,
    output  reg         ram_comp
);
parameter [2:0] idle = 3'd0, wait_clbp = 3'd1,clbp = 3'd2, hcu = 3'd3, wait_hcu = 3'd4, comparator = 3'd5;
reg [2:0] cs, ns;

always@(posedge clk or posedge rst)begin
    if(rst)
        cs <= idle;
    else
        cs <= ns;
end

//state
always@(*) begin
    if(mode) begin//predict
        case(cs)
            idle: begin
                ns = clbp;
            end
            wait_clbp:
                ns = clbp;
            clbp:begin
                if(lbp_finish)
                    ns = hcu;
                else 
                    ns = clbp;
            end
            hcu:begin
                if(hcu_finish)
                    ns = comparator;
                else 
                    ns = hcu;
            end
            comparator:begin
                if(comparator_finish)
                    ns = idle;
                else
                    ns = comparator;
            end
            
		default:
				ns = idle;
		
        endcase
    end
    else begin
        case(cs)
            idle: begin
                if(enable)
                    ns = wait_clbp;
                else 
                    ns = idle;
            end
            wait_clbp:begin
                ns = clbp;
            end
            clbp:begin
                if(lbp_finish)
                    ns = hcu;
                else 
                    ns = clbp;
            end
            hcu:begin
                if(hcu_finish)
                    ns = wait_hcu;
                else 
                    ns = hcu;
			end
            wait_hcu:begin
                ns = wait_clbp;
            end
			default:
					ns = idle;
        endcase
                
    end
end
//signal
always@(posedge clk or posedge rst) begin
    if(rst)begin
        lbp_enable <= 1'd0;
        hcu_enable <= 1'd0;
        ram_clbp <= 1'd0;
        ram_comp <= 1'd0;
        comparator_enable <= 1'd0;
        id_wen <= 1'd0;
        id_addr <= 8'd0;
        id_wdata <= 5'd0;
    end
    else begin
        if(mode) begin//predict
            case(cs)
                idle: begin
                    lbp_enable <= 1'd1;
                    hcu_enable <= 1'd0;
                    ram_clbp <= 1'd0;
                    ram_comp <= 1'd0;
                    comparator_enable <= 1'd0;

                end
                wait_clbp:begin
                    ram_clbp <= 1'd0;
                    lbp_enable <= 1'd1;
                    
                end
                    
                clbp:begin
                    lbp_enable <= 1'd0;
                    
                    if(lbp_finish)begin
                        hcu_enable <= 1'd1;
                        ram_clbp <= 1'd1;
                    end
                end
                hcu:begin
                    hcu_enable <= 1'd0;
                    if(hcu_finish) begin
                        comparator_enable <= 1'd1;
                        ram_comp <= 1'd1;
                    end
                end
                comparator:begin
                    comparator_enable <= 1'd0;
                end

            endcase
        end
        else begin
            case(cs)
                idle: begin
                    if(enable)
                        lbp_enable <= 1'd1;
                    else
                        hcu_enable <= 1'd0;
                    ram_clbp <= 1'd0;
                    id_wen <= 1'd1;
                    id_addr <= 8'd0;
                    id_wdata <= id;
                end
                wait_clbp:begin
                    
                    //id_wdata <= id;
                    //id_wen <= 1'd1;
                    
                    lbp_enable <= 1'd1;
                    ram_clbp <= 1'd0;
                end
                clbp:begin
                    lbp_enable <= 1'd0;
                    id_wen <= 1'd0;
                    
                    //id_wdata <= id;
                    if(lbp_finish)begin
                        ram_clbp <= 1'd1;
                        hcu_enable <= 1'd1;
                        id_addr <= id_addr + 8'd1;
                    end
                end
                hcu:begin
                    
                    hcu_enable <= 1'd0;
                    
                    if(hcu_finish)begin
                        ram_clbp <= 1'd0;
                        id_wen <= 1'd1;
                        id_wdata <= id;
                    end
                end
                wait_hcu:begin
                    id_wdata <= id;
                end
            endcase
        end
    end
end
endmodule