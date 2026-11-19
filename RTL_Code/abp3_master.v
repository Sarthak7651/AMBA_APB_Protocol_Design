module apb3_m
  (input pclk,
   input presetn,
   input [3:0] addrin,
   input [7:0] datain,
   input wr,
   input newd,
   input pready,
   input [7:0]prdata,
   
   output reg psel,
   output reg penable,
   output reg pwrite,
   output reg [3:0] paddr,
   output reg [7:0] pwdata,
   output reg slverr,
   output [7:0] dataout );
  
  localparam [1:0] idle=0,setup=1,enable=2;
  reg [1:0] state,nstate;
  
  always @(posedge pclk or negedge presetn) 
    begin
      if(!presetn) 
        state <= idle;
      else 
        state <= nstate;
    end
  
  always @(*) begin
    case(state)
      idle : nstate = newd ? setup : idle;
      
      setup : nstate = enable;
      
      enable : begin
        if (newd) nstate = pready ? setup : enable;
        else nstate = idle;
      end
      
      default : nstate = idle;
      
    endcase
  end
  
    
    always @(posedge pclk or negedge presetn) 
      begin
        if(!presetn) psel<=1'b0;
        else if(nstate == idle) psel<=1'b0;
        else if(nstate == setup || nstate == enable) psel<=1'b1;
        else psel <= 1'b0;
      end
    
    //output logic
    
    always @(posedge pclk or negedge presetn)
      begin
        if(!presetn) 
          begin
            penable <= 1'b0;
            pwrite <= 1'b0;
            paddr <= 1'b0;
            pwdata <= 1'b0;
          end
        
        else if(nstate == idle)
          begin
            penable <= 1'b0;
            pwrite <= 1'b0;
            paddr <= 1'b0;
            pwdata <= 1'b0;
          end
        
        else if( nstate == setup) 
          begin
            penable <= 1'b0;
            paddr <= addrin;
            pwrite <= wr;
            
            if(wr == 1'b1) pwdata <= datain;
          end
        
        else if (nstate == enable) penable <= 1'b1;
        
      end
    
  assign dataout = (psel && penable && !wr ) ? prdata : 8'h00;
    
    endmodule
