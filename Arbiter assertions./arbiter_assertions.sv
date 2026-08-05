//Arbiter is a hardware block that decides which request need to be acknowledged at the time of multiple requests.
//Scenario: There are four drivers which can drive the data to SRAM
// 1. AXI  2. CPU.  3. GPU.  
bit transaction_active_w;
always @(posedge ref_clk) begin
  if(!cpl_reset) begin
    transaction_active_w <= 1'b0;
  end else begin
    if(!transaction_active_w && |write_req) begin
      //start new transaction only when idle and req is detected
      transaction_active_w <= 1'b1;
    end else if (transaction_active_w && $$past(|write_ack, 1)) begin
        //End transaction one cycle after ack was high (ack goes low)
        transaction_active_w <= 1'b0;
    end
  end
end
//----------------WRITE OPERATION ASSERTIONS------------------
//Each write_ack stays high for exactly one cycle.
//----------------------------------------------------------
property p_write_ack_one_cycle(int i);
  @(posedge ref_clk) disable iff(!cpl_reset)
  $rose(write_ack[i]) |=> !write_ack[i];
endproperty

A_WRITE_ACK_ONE_CYCLE_REQ0: assert property(p_write_ack_one_cycle(0));
A_WRITE_ACK_ONE_CYCLE_REQ1: assert property(p_write_ack_one_cycle(1));
A_WRITE_ACK_ONE_CYCLE_REQ2: assert property(p_write_ack_one_cycle(2));
A_WRITE_ACK_ONE_CYCLE_REQ3: assert property(p_write_ack_one_cycle(3));

C_WRITE_ACK_ONE_CYCLE_REQ0: cover property(p_write_ack_one_cycle(0));
C_WRITE_ACK_ONE_CYCLE_REQ1: cover property(p_write_ack_one_cycle(1));
C_WRITE_ACK_ONE_CYCLE_REQ2: cover property(p_write_ack_one_cycle(2));
C_WRITE_ACK_ONE_CYCLE_REQ3: cover property(p_write_ack_one_cycle(3));

//-----------------------------------------------------------
//High priority wrute requests must wait if a transaction is ongoing
//---------------------------------------------------------------

//write req0 has highest priority - gets ack when no transaction is active
property p_write_req0_priority_when_idle;
  @(posedge reg_clk) disable iff(!cpl_reset)
  ((write_req[0] || $$rose(write_req[0])) && !transaction_active_w && !$$fell(write_req[0])) |-> s_eventually write_ack[0];
endproperty
property p_write_req1_priority_when_idle;
  @(posedge reg_clk) disable iff(!cpl_reset)
  ((write_req[1] || $$rose(write_req[1])) && !write_req[0] && !transaction_active_w && !$$fell(write_req[1])) |-> s_eventually write_ack[1];
endproperty
property p_write_req2_priority_when_idle;
  @(posedge reg_clk) disable iff(!cpl_reset)
  ((write_req[2] || $$rose(write_req[2])) && !write_req[1] && !write_req[0] && !transaction_active_w && !$$fell(write_req[2])) |-> s_eventually write_ack[2];
endproperty
property p_write_req3_priority_when_idle;
  @(posedge reg_clk) disable iff(!cpl_reset)
  ((write_req[3] || $$rose(write_req[3])) && !write_req[2] && !write_req[1] && !write_req[0] && !transaction_active_w && !$$fell(write_req[3])) |-> s_eventually write_ack[3];
endproperty

A_WRITE_REQ0_PRIORITY_WHEN_IDLE: assert property(p_write_req0_priority_when_idle);
A_WRITE_REQ1_PRIORITY_WHEN_IDLE: assert property(p_write_req1_priority_when_idle);
A_WRITE_REQ2_PRIORITY_WHEN_IDLE: assert property(p_write_req2_priority_when_idle);
A_WRITE_REQ3_PRIORITY_WHEN_IDLE: assert property(p_write_req3_priority_when_idle);


C_WRITE_REQ0_PRIORITY_WHEN_IDLE: cover property(p_write_req0_priority_when_idle);
C_WRITE_REQ1_PRIORITY_WHEN_IDLE: cover property(p_write_req1_priority_when_idle);
C_WRITE_REQ2_PRIORITY_WHEN_IDLE: cover property(p_write_req2_priority_when_idle);
C_WRITE_REQ3_PRIORITY_WHEN_IDLE: cover property(p_write_req3_priority_when_idle);

//-----------------------------------------------------------
//WRITE NON-PREEMPTION - no interruption of ongoing write transactions.
//---------------------------------------------------------------

property p_write_no_preenption_req0;
  @(posedge ref_clk) disable iff(!cpl_reset)
  write_ack[0] |->(!write_ack[1]) && !write_ack[2] && !write_ack[3]);
endproperty

property p_write_no_preenption_req1;
  @(posedge ref_clk) disable iff(!cpl_reset)
  write_ack[1] |->(!write_ack[0]) && !write_ack[2] && !write_ack[3]);
endproperty

property p_write_no_preenption_req2;
  @(posedge ref_clk) disable iff(!cpl_reset)
  write_ack[2] |->(!write_ack[1]) && !write_ack[1] && !write_ack[3]);
endproperty

property p_write_no_preenption_req3;
  @(posedge ref_clk) disable iff(!cpl_reset)
  write_ack[3] |->(!write_ack[0]) && !write_ack[1] && !write_ack[2]);
endproperty

A_WRITE_NO_PREEMPTION_REQ0: assert property(p_write_no_preemption_req0);
A_WRITE_NO_PREEMPTION_REQ1: assert property(p_write_no_preemption_req1);
A_WRITE_NO_PREEMPTION_REQ2: assert property(p_write_no_preemption_req2);
A_WRITE_NO_PREEMPTION_REQ3: assert property(p_write_no_preemption_req3);

C_WRITE_NO_PREEMPTION_REQ0: cover property(p_write_no_preemption_req0);
C_WRITE_NO_PREEMPTION_REQ1: cover property(p_write_no_preemption_req1);
C_WRITE_NO_PREEMPTION_REQ2: cover property(p_write_no_preemption_req2);
C_WRITE_NO_PREEMPTION_REQ3: cover property(p_write_no_preemption_req3);

//-----------------------------------------------------------
//Each write request eventually gets acknowledged.
//---------------------------------------------------------------

property p_write_req0_eventually_acked;
  @(posedge ref_clk) disable iff(!cpl_reset)
  (write_req[0] && (write_req[1] || write_req[2] || write_req[3]) && !transaction_active_w && !$$fell(write_req[0])) |-> s_eventually write_ack[0];
endproperty

property p_write_req0_eventually_acked;
  @(posedge ref_clk) disable iff(!cpl_reset)
  (write_req[0] && (write_req[1] || write_req[2] || write_req[3]) && !transaction_active_w && !$$fell(write_req[0])) |-> s_eventually write_ack[0];
endproperty

property p_write_req0_eventually_acked;
  @(posedge ref_clk) disable iff(!cpl_reset)
  (write_req[0] && (write_req[1] || write_req[2] || write_req[3]) && !transaction_active_w && !$$fell(write_req[0])) |-> s_eventually write_ack[0];
endproperty

property p_write_req0_eventually_acked;
  @(posedge ref_clk) disable iff(!cpl_reset)
  (write_req[0] && (write_req[1] || write_req[2] || write_req[3]) && !transaction_active_w && !$$fell(write_req[0])) |-> s_eventually write_ack[0];
endproperty

A_WRITE_REQ0_EVENTUALLY_ACKED: assert property(p_write_req0_eventually_acked);
A_WRITE_REQ1_EVENTUALLY_ACKED: assert property(p_write_req1_eventually_acked);
A_WRITE_REQ2_EVENTUALLY_ACKED: assert property(p_write_req2_eventually_acked);
A_WRITE_REQ3_EVENTUALLY_ACKED: assert property(p_write_req3_eventually_acked);

C_WRITE_REQ0_EVENTUALLY_ACKED: assert property(p_write_req0_eventually_acked);
C_WRITE_REQ1_EVENTUALLY_ACKED: assert property(p_write_req1_eventually_acked);
C_WRITE_REQ2_EVENTUALLY_ACKED: assert property(p_write_req2_eventually_acked);
C_WRITE_REQ3_EVENTUALLY_ACKED: assert property(p_write_req3_eventually_acked);