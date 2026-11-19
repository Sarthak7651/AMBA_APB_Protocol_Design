module apb3_s
  (input pclk,
   input presetn,
   input psel,
   input penable,
   input pwrite,
   input [3:0] paddr,
   input [7:0] pwdata,

   input s_wait,
   
   output reg pready,
   output reg [7:0] prdata,
   output reg pslverr);
  
  reg [7:0] mem [0:15];
  localparam [1:0] idle=0,write=1,read=2;
  reg [1:0] state,nstate;
  
  always @(posedge pclk or negedge presetn) 
    begin
      if(!presetn) 
        state <= idle;
      else
        state <= nstate;
    end
  
  always @(*)
  begin
    nstate = idle;
    pready = 1'b0;
    prdata = 8'h00;
    case(state) 
      idle : 
        begin
          if(psel && pwrite) 
            nstate = write;
          else if (psel && !pwrite) 
            nstate = read;
          else 
            nstate = idle;
        end
      
      write : 
        begin
          if(psel && penable)
            begin 
              if(s_wait) nstate = write;
              else begin
              pready = 1'b1;
              mem[paddr] = pwdata;
              nstate = idle;
              end
            end
          else 
            begin
              nstate = idle;
            end
        end
      
      read :
        begin
          if(psel && penable)
            begin
              if(s_wait) nstate = read;
              else begin
              pready = 1'b1;
              prdata = mem[paddr];
              nstate = idle;
              end
            end
          else nstate = idle;
        end
      default : nstate = idle;
      
    endcase
  end
  
endmodule
            
      
      
