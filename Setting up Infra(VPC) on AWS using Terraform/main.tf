// Imagine AWS manual VPC creation and follow TF registry for reference:

resource "aws_vpc" "myvpc" {   //VPC creation
  cidr_block = var.cidr

}
resource "aws_subnet" "mysub1" { // Subnet1 creation
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
}
resource "aws_subnet" "mysub2" { // Subnet2 creation
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
}
resource "aws_internet_gateway" "igw" {  // Create Internet gateway
    vpc_id = aws_vpc.myvpc.id
}
resource "aws_route_table" "myrt" { // Route table : packets are forwarded between the subnets within your VPC
    vpc_id = aws_vpc.myvpc.id
    route {
            cidr_block = "0.0.0.0/0"
            gateway_id = aws_internet_gateway.igw.id
        }
    }
resource "aws_route_table_association" "myrta1" { // association between a route table and a subnet
    subnet_id = aws_subnet.mysub1.id
    route_table_id = aws_route_table.myrt.id
    }
resource "aws_route_table_association" "myrta2" {
    subnet_id = aws_subnet.mysub2.id
    route_table_id = aws_route_table.myrt.id
    }
resource "aws_security_group" "mysg" { // Allow inbound and outbound traffic
  name        = "websg"
  vpc_id      = aws_vpc.myvpc.id


ingress {
    description = "HTTP"
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  
}
ingress {
    description = "SSH"
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  
}
egress {

    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks =["0.0.0.0/0"]
  
}
}
resource "aws_s3_bucket" "s3example" {  //Create s3 bucket
    bucket = "my-tf-test-bucket"
}
resource "aws_instance" "myec2_1" { // Create Ec2 instances
    ami           = "ami-id-here"
    instance_type = "t3.micro"
    vpc_security_group_ids = [aws_security_group.mysg.id]
    subnet_id = aws_subnet.mysub1.id
    user_data = base64encode(file("userdata.sh"))
}
resource "aws_instance" "myec2_2" {
    ami           = "ami-id-here"
    instance_type = "t3.micro"
    vpc_security_group_ids = [aws_security_group.mysg.id]
    subnet_id = aws_subnet.mysub2.id
    user_data = base64encode(file("userdata2.sh"))
}
resource "aws_alb" "mylb" {   // Create Application load banlancer
    name = "mylb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.mysg.id]
    subnets = [aws_subnet.mysub1.id,aws_subnet.mysub2.id]

}
resource "aws_lb_target_group" "albtg" { //2. The receiving listener evaluates the incoming request against the rules you specify, and if applicable, routes the request to the appropriate target group
    name = "albtg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.myvpc.id
    health_check {
      path = "/"
      port = "traffic-port"
    }
}
resource "aws_lb_target_group_attachment" "attach1" { // Targets attached as EC2
    target_group_arn = aws_lb_target_group.albtg.arn
    target_id = aws_instance.myec2_1.id
    port = 80
}
resource "aws_lb_target_group_attachment" "attach2" {
    target_group_arn = aws_lb_target_group.albtg.arn
    target_id = aws_instance.myec2_2.id
    port = 80
}
resource "aws_lb_listener" "listener" { //1. The listeners in your load balancer receive requests matching the protocol and port that you configure.
    load_balancer_arn = aws_alb.mylb.arn
    port = 80
    protocol = "HTTP"
    default_action {
        target_group_arn = aws_lb_target_group.albtg.arn
        type = "forward"
    }
}

output "loadbalancerdns" {
    value = aws_alb.mylb.dns_name
}