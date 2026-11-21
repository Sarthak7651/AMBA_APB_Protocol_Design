module apb_multi_slave
  (
    input pclk,
    input presetn,
    input [3:0] paddr,
    input penable,
    input psel,
    input [7:0] pwdata,
    input pwrite,

    output reg [7:0] prdata,
    output reg pready,
    output pslverr
  );

  localparam [1:0] idle = 0,write = 1,read = 2;
  reg [7:0] mem [0:15];

  reg [1:0] state,nstate;

  bit addr_err,addv_err,data_err,setup_apb_err;
  // setup - correct apb cycles
  //  addr_range - should be less than 16
  //   addr_val - be greater than or equal to 0
  //   data_val - be greater than or equal to 0  
/*
Transactions that receive an error, might or might not have changed the state of the peripheral. 
This is peripheral-specific and either is acceptable. 
When a write transaction receives an error this does not mean that the register within the peripheral 
has not been updated. Read transactions that receive an error can return invalid data.
 There is no requirement for the peripheral to drive the data bus to all 0s for a read error.
*/

  always @(posedge pclk , negedge presetn)
    begin
      if(!presetn)
        state <= idle;
      else 
        state <= nstate;
    end

  always @(*) 
    begin
      case(state)
        idle : begin
          prdata = 8'h00;
          pready = 1'b0;
          if(psel && pwrite) nstate = write;
          else if (psel & !pwrite) nstate = read;
          else nstate = idle;
        end

        write : 
        begin
          if(psel && penable)
            begin
              if(!addr_err && !addv_err && !data_err)
                begin
                  pready = 1'b1;
                  mem[paddr] = pwdata;
                  nstate = idle;
                end
              else begin
                nstate = idle;
                pready = 1'b1;
              end
            end
        end

        read :
          begin
            if(psel && penable)
              begin
                if(!addr_err && !addv_err && !data_err)
                  begin
                    pready = 1'b1;
                    prdata = mem[paddr];
                    nstate = idle;
                  end
                else begin
                  pready = 1'b1;
                  prdata = 8'h00;
                  nstate = idle;
                end
              end
          end

        default : 
          begin
            nstate = idle;
            prdata = 8'h00;
            pready = 1'b0;
          end
      endcase
    end

  //checking valid value of address
  reg av_t = 0;//address value 
  always@(*) 
    begin
      if(paddr >= 0)
        av_t = 1'b0;
      else 
        av_t = 1'b1;
    end

  //checking valid value of address
  reg dv_t = 0;//data value
  always @(*) 
    begin
      if(pwdata >= 0)
        dv_t = 1'b0;
      else 
        dv_t = 1'b1;
    end

  //address range error
  assign addr_err = ((nstate == write || read) && (paddr > 15)) ? 1'b1 : 1'b0;
  //address value error
  assign addv_err = (nstate == write || read) ? av_t : 1'b0;
  //data error
  assign data_err = (nstate == write || read) ? dv_t : 1'b0;

  assign pslverr =(psel && penable) ? (addv_err || addr_err || data_err) : 1'b0;

endmodule       
