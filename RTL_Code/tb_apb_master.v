module tb_m;
  reg pclk=0;
  reg presetn=0;
  reg [3:0] addrin;
  reg [7:0] datain;
  reg wr;
  reg newd;
  reg [7:0] prdata;
  reg pready;

  wire psel;
  wire penable;
  wire [3:0] paddr;
  wire [7:0] pwdata;
  wire pwrite;
  wire [7:0] dataout;

  apb_m dut (
        .pclk(pclk),
        .presetn(presetn),
        .addrin(addrin),
        .datain(datain),
        .wr(wr),
        .newd(newd),
        .prdata(prdata),
        .pready(pready),
        .psel(psel),
        .penable(penable),
        .slverr(slverr),
        .paddr(paddr),
        .pwdata(pwdata),
        .pwrite(pwrite),
        .dataout(dataout)
    );

  always #10 pclk=~pclk;

  initial begin
    presetn = 0;
    repeat(5) @(posedge pclk);
    presetn = 1;
    newd = 1;
    addrin = 4;
    datain = 255;
    wr = 1;
    prdata = 255;
    @(posedge pclk);
    pready = 1'b1;
    @(posedge pclk);
    
    
    newd = 1;
    addrin = 4;
    datain = 0;
    wr = 0;
    prdata = 255;
    @(posedge pclk);
    pready = 1'b1;
    @(posedge pclk);
    newd = 1'b0;
    @(posedge pclk);
    end
    
    initial begin
    #170;
    $stop;
    end
endmodule

    

  
