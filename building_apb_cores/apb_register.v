module apb_reg
  (
    input rst, //reset input
    input pclk, //apb clock input
    input presetn, //apb reset input
    input psel, // apb select input
    input [31:0] paddr,//apb address input
    input [31:0] pwdata,//apb write data input
    input penable,//apb enable input
    input pwrite,//apb write enable input
    
    output reg [31:0] prdata,//apb read data output
    output reg pready //apbb read data ready output
  );

  reg [31:0] GPIO_REG = 32'h0;
  localparam GPIO_REG_ADDR = 32'h0000_0000;

  parameter idle=0,check_op=1,write_data=2,read_data=3,send_ready=4;
  reg [2:0] state=idle;
  reg [31:0] addr,wdata;

  //apb fifo control logic
  always @(posedge pclk or negedge rst) begin
    if(rst==0) begin
      pready <= 0;
      state <= idle;
      prdata <= 0;
      addr <= 0;
      wdata <= 0;
    end else begin
      case(state) 
        idle :
          begin
            pready <= 0;
            prdata <= 0;
            addr <= 0;
            wdata <= 0;
            state <= check_op;
          end

        check_op :
          begin
            if(penable && psel && pwrite && paddr == 0)
              begin
                state <= write_data;
                addr <= paddr;
                wdata <= pwdata;
              end
            else if(penable && psel && !pwrite && paddr == 0)
              begin
                state <= read_data;
                addr <= paddr;
              end
            else
              state <= check_op;
          end

        write_data:
          begin
            GPIO_REG <= wdata;
            pready <= 1'b1;
            state <= send_ready;
          end

        read_data :
          begin
            pready <= 1'b1;
            prdata <= GPIO_REG;
            state <= send_ready;
          end

        send_ready :
          begin
            state <= check_op;
            pready <= 1'b0;
          end

      endcase
    end
  end
endmodule
            

        
            
            
    
