module KT(
    clk,
    rst_n,
    in_valid,
    in_x,
    in_y,
    move_num,
    priority_num,
    out_valid,
    out_x,
    out_y,
    move_out
);

input clk,rst_n;
input in_valid;
input [2:0] in_x,in_y;
input [4:0] move_num;
input [2:0] priority_num;

output reg out_valid;
output reg [2:0] out_x,out_y;
output reg [4:0] move_out;

parameter idle = 0;
parameter read = 1;
parameter check = 2;
parameter next_cnt = 3;
parameter next_direct = 4;
parameter exe = 5;
parameter back = 6;
parameter check_back = 7;
parameter finish = 8;



reg [3:0]cs, ns;
reg [4:0]read_cnt;
reg [2:0] x_cur;
reg [2:0] y_cur;
reg [4:0] move_cnt;
reg [2:0] priority_dir, last_dir;
reg [2:0] visited_x [0:24];
reg [2:0] visited_y [0:24];
reg [24:0] visited_table;
reg [2:0]temp_dir;
reg [2:0] pre_direct [0:24];
wire signed [3:0] move_x [0:7];
wire signed [3:0] move_y [0:7];
//move
assign move_x[0] = -1;
assign move_x[1] =  1;
assign move_x[2] =  2;
assign move_x[3] =  2;
assign move_x[4] =  1;
assign move_x[5] = -1;
assign move_x[6] = -2;
assign move_x[7] = -2;
assign move_y[0] =  2;
assign move_y[1] =  2;
assign move_y[2] =  1;
assign move_y[3] = -1;
assign move_y[4] = -2;
assign move_y[5] = -2;
assign move_y[6] = -1;
assign move_y[7] =  1;
wire signed [3:0] check_x, check_y;
assign check_x = x_cur + move_x[temp_dir];
assign check_y = y_cur + move_y[temp_dir];
assign last_dir = priority_dir - 1;
//cs
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		cs <= idle;
	else
		cs <= ns;
end
//ns
always@(*)begin
	case (cs)
		idle: begin//0
			if(in_valid)
				ns = read;
			else
				ns = idle;
		end
		read:begin//1
			if(in_valid)
				ns = read;
			else
				ns = check;
		end
		check:begin//2
			if(check_x < 0 || check_x > 4 || check_y < 0 || check_y > 4 || visited_table[5 * check_x +check_y] == 1)
				ns = next_direct;
			else
				ns = next_cnt;
		end
		next_cnt://3
			ns = exe;
		next_direct:begin//4
			if(temp_dir == last_dir)
				ns = back;
			else
				ns = exe;
		end
		exe:begin//5
			if(read_cnt==25)
				ns = finish;
			else
				ns = check;
		end
		back://6
			ns = check_back;
		check_back:begin//7
			if(pre_direct[read_cnt] == last_dir)
				ns = back;
			else
				ns = exe;
		end
		finish://8
			if (move_out ==24) 
				ns = idle;
			else
				ns = finish;
		default: 
			ns = idle;
	endcase
end
//move_cnt priority_dir
always @(posedge clk) begin
	if(ns ==read && !read_cnt)begin
		move_cnt <= move_num;
		priority_dir <= priority_num;
		end
	else begin
		if(ns ==read && !read_cnt)begin
		move_cnt <= move_cnt;
		priority_dir <= priority_dir;
		end
	end
end
//read_cnt
always @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		read_cnt <= 0;
	else if(ns == idle)
		read_cnt <= 0;
	else if(ns == read)
		read_cnt <= read_cnt + 1;
	else if(cs == next_cnt)
		read_cnt <= read_cnt + 1;
	else if(cs == back)
		read_cnt <= read_cnt - 1;
	else
		read_cnt <= read_cnt;
end
//cur
always @(posedge clk) begin
	if(ns == read)begin
		x_cur <= in_x;
		y_cur<= in_y;
	end
	else if(cs == next_cnt)begin
		x_cur <= check_x;
		y_cur <= check_y;
	end
	else if(cs == back)begin
		x_cur <= visited_x[read_cnt - 2];
		y_cur <= visited_y[read_cnt - 2];
	end
	else begin
		x_cur <= x_cur;
		y_cur <= y_cur;
	end	
end
//visited_pos
integer i;
always @(posedge clk) begin
	if(ns == read)begin
		visited_x[read_cnt] <= in_x;
		visited_y[read_cnt] <= in_y;
	end
	else if(cs == exe)begin
		visited_x[read_cnt - 1] <= x_cur;
		visited_y[read_cnt - 1] <= y_cur;
	end
	else if(cs == back)begin
		visited_x[read_cnt-1] <= 'bx;
		visited_y[read_cnt-1] <= 'bx;
	end
	else if( move_out ==25)begin
		for(i = 0;i<25;i= i+1)begin
			visited_x[i] <= 'bx;
			visited_y[i] <= 'bx;
		end
	end
end
//temp_dir
always @(posedge clk) begin
	if(cs == read || cs == next_cnt)
		temp_dir <= priority_dir;
	else if(cs == next_direct)
		temp_dir <= temp_dir + 1;
	else if(cs == back)
		temp_dir <= pre_direct[read_cnt -1] + 1;
end
//visited_table
always @(posedge clk ) begin
	if(ns == read)
	begin
		if(read_cnt <= move_cnt)
			visited_table[in_x *5 +in_y] <= 1;
	end
	else if(cs == next_cnt)
		visited_table[5*check_x +check_y]<=1;
	else if(cs == back)
		visited_table[5*x_cur+y_cur] <= 'bx;
	else if(cs == finish)
		visited_table <= 'bx;
	else
		visited_table <= visited_table;
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
		move_out <= 0;
		out_x <= 0;
		out_y <= 0;
	end
	else if(ns == finish || cs ==finish ) begin
		if(move_out < 25)begin
			if(move_out==25)begin
				out_valid <= 0;
				move_out <= 0;
				out_x <= 0;
				out_y <= 0;
			end
			else begin
				out_valid <= 1;
				move_out <= move_out + 1;
				out_x <= visited_x [move_out];
				out_y <= visited_y [move_out];
			end
		end
	end
	else begin
		out_valid <= 0;
		move_out <= 0;
		out_x <= 0;
		out_y <= 0;
	end
end
//pre_direc
integer j;
always @(posedge clk ) begin
	if(cs == next_cnt)
		pre_direct[read_cnt]<=temp_dir;
	else if(cs == finish)begin
		for(j = 0;j < 25;j= j+1)begin
			pre_direct[j] <= 'bx;
		end
	end
	else if(cs== check_back && ns ==exe)
		pre_direct[read_cnt] <= 'bx;
end
endmodule
