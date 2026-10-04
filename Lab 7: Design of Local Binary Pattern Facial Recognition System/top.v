`include "../rtl/CLBP.v"
`include "../rtl/HCU.v"
`include "../rtl/DCU.v"
`include "../rtl/Comparator.v"
`include "../rtl/Controller.v"

module top(
    input           clk,
    input           rst,
    input           enable,
    input           mode,
    input           valid, 
    input   [4:0]   id,
    input   [3:0]   gridX,
    input   [3:0]   gridY,

    // CLBP I/O & LBP RAM
	output 	[11:0]	gray_addr,
	output			gray_ren,
	input	[7:0]	gray_rdata,
    output  [11:0]  lbp_addr,
    output          lbp_wen,
	output			lbp_ren,
    input   [7:0]   lbp_rdata,
	output	[7:0] 	lbp_wdata,
	output	[24:0]	theta,
	output			theta_valid,
	input	[24:0]	cos_data,
	input			cos_valid,
	input	[24:0]	sin_data,
	input			sin_valid,
	output			lbp_finish,
	
    // ID RAM I/O
    output  [7:0]   id_addr,
    output  [4:0]   id_wdata,
    output          id_wen,
    output          id_ren,
    input   [4:0]   id_rdata,

    // HIST TRAIN RAM I/O
    output  [20:0]  hist_addr_train,
    output  [7:0]   hist_wdata_train,
    output          hist_wen_train,
    output          hist_ren_train,
    input   [7:0]   hist_rdata_train,

    // HIST PREDICT RAM I/O
    output  [13:0]  hist_addr_predict,
    output  [7:0]   hist_wdata_predict,
    output          hist_wen_predict,
    output          hist_ren_predict,
    input   [7:0]   hist_rdata_predict,  

    output          hcu_finish,
    output          done,
    output  [4:0]   label,
    output  [17:0]  minDistance
);

wire ram_clbp, ram_comp;
//controller wire
wire hcu_enable, lbp_enable;
wire [3:0] gridX_o, gridY_o;//to hcu
wire comparator_enable;//to comparator
wire [7:0] c_id_addr, id_counter;// id_addr -> histcount
wire c_id_wen;
wire [4:0] c_id_wdata;

//hcu wire
wire hcu_done, clbp_ren, hcu_ren, hcu_wen;
wire pre_hcu_wen, pre_hcu_ren;
wire [11:0] h_lbp_addr;
wire [20:0] hcu_addr;
wire [13:0] pre_hcu_addr;
wire [7:0] h_lbp_rdata, hcu_rdata, hcu_wdata;
wire [7:0] pre_hcu_rdata, pre_hcu_wdata;
assign hcu_finish = hcu_done;

//clbp wire
wire lbp_done, clbp_wen;
wire [11:0] c_lbp_addr;
wire [7:0] clbp_data;
assign lbp_finish = lbp_done;
//dcu wire
wire [20:0] dcu_addr;
wire [13:0] pre_dcu_addr;
wire [7:0] dcu_rdata, pre_dcu_rdata;
wire [20:0] hist_addr_offset;
wire dcu_valid, dcu_ren, pre_dcu_ren;
wire [17:0] distance;
//comparator wire
wire dcu_enable;
wire comparator_done, c_id_ren;
wire [4:0] c_id;
assign done = comparator_done;

    // put your design here
Controller controller( .clk(clk),  .rst(rst),  .mode(mode),  .enable(enable),  .valid(valid),  .id(id),
                    .id_addr(c_id_addr),  .id_wdata(c_id_wdata),  .id_wen(c_id_wen),
                    .lbp_enable(lbp_enable),  .lbp_finish(lbp_done),  .ram_clbp(ram_clbp),  .gridX_i(gridX),
                    .gridY_i(gridY),  .hcu_enable(hcu_enable),  .gridX_o(gridX_o), .gridY_o(gridY_o),
                    .hcu_finish(hcu_done),  .comparator_finish(comparator_done),
                    .comparator_enable(comparator_enable),
                    .ram_comp(ram_comp)
                    );   
// CLBP & Controller MUX (1:0)
assign lbp_addr = (ram_clbp) ? h_lbp_addr : c_lbp_addr;
assign lbp_wen = (ram_clbp) ? 1'd0 : clbp_wen;
assign lbp_wdata = (ram_clbp) ? 8'd0 : clbp_data;
assign lbp_ren = (ram_clbp) ? clbp_ren : 1'd0; 
assign h_lbp_rdata = (ram_clbp) ? lbp_rdata : 8'd0;

CLBP clbp(  .clk(clk), .rst(rst), .enable(lbp_enable), .lbp_data(clbp_data), .gray_addr(gray_addr),
            .gray_OE(gray_ren), .gray_data(gray_rdata), .lbp_addr(c_lbp_addr), .lbp_WEN(clbp_wen),
            .theta(theta), .theta_valid(theta_valid), .cos_data(cos_data), .cos_valid(cos_valid),
            .sin_data(sin_data), .sin_valid(sin_valid), .finish(lbp_done)
        );

HCU hcu(    .clk(clk),  .rst(rst),  .mode(mode), .enable(hcu_enable),  .gridX(gridX_o),  .gridY(gridY_o), 
            .lbp_ren(clbp_ren), .lbp_addr(h_lbp_addr), .lbp_rdata(h_lbp_rdata),
            .hist_wen_train(hcu_wen),  .hist_wdata_train(hcu_wdata),  .hist_addr_train(hcu_addr),
            .hist_ren_train(hcu_ren),  .hist_rdata_train(hcu_rdata),  .hist_wen_predict(pre_hcu_wen),
            .hist_wdata_predict(pre_hcu_wdata),  .hist_addr_predict(pre_hcu_addr),
            .hist_ren_predict(pre_hcu_ren),  .hist_rdata_predict(pre_hcu_rdata),
            .done(hcu_done)
        );

// HCU & DCU Train MUX
assign hist_addr_train = (ram_comp) ? dcu_addr : hcu_addr;
assign hist_wen_train = (ram_comp) ? 1'd0 : hcu_wen;
assign hist_wdata_train = (ram_comp) ? 8'd0 : hcu_wdata;
assign hist_ren_train = (ram_comp) ? dcu_ren : hcu_ren;
assign dcu_rdata = (ram_comp) ? hist_rdata_train : 8'd0;
assign hcu_rdata = (ram_comp) ? 8'd0 : hist_rdata_train;

// HCU & DCU Predict MUX
assign hist_addr_predict = (ram_comp) ? pre_dcu_addr : pre_hcu_addr;
assign hist_wen_predict = (ram_comp) ? 1'd0 : pre_hcu_wen;
assign hist_wdata_predict = (ram_comp) ? 8'd0 : pre_hcu_wdata;
assign hist_ren_predict = (ram_comp) ? pre_dcu_ren : pre_hcu_ren;
assign pre_dcu_rdata = (ram_comp) ? hist_rdata_predict : 8'd0;
assign pre_hcu_rdata = (ram_comp) ? 8'd0 : hist_rdata_predict;

DCU dcu(    .clk(clk),  .rst(rst), .enable(dcu_enable), .hist_addr_offset(hist_addr_offset),
            .hist_addr_train(dcu_addr), .hist_ren_train(dcu_ren),  .hist_rdata_train(dcu_rdata),
            .hist_addr_predict(pre_dcu_addr),  .hist_ren_predict(pre_dcu_ren),
            .hist_rdata_predict(pre_dcu_rdata),  .distance(distance),  .valid(dcu_valid)
        );
//Controller & Comparator MUX (1:0)
assign id_addr = (ram_comp) ? id_counter : c_id_addr;
assign id_wen = (ram_comp) ? 1'd0 : c_id_wen;
assign id_ren = (ram_comp) ? c_id_ren : 1'd0;
assign c_id = (ram_comp) ? id_rdata : 1'd0;
assign id_wdata = (ram_comp) ? 1'd0 : c_id_wdata;

Comparator comparator(  .clk(clk), .rst(rst), .enable(comparator_enable),  .histcount(c_id_addr),
                        .dcu_valid(dcu_valid),  .distance(distance),  .id(c_id),
                        .id_ren(c_id_ren),  .id_counter(id_counter),  .dcu_enable(dcu_enable),  .label(label),
                        .minDistance(minDistance),  .hist_addr_offset(hist_addr_offset),
                        .done(comparator_done)
                    );


endmodule