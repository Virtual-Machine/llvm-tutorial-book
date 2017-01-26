;Standard Library

@.puts_float = private unnamed_addr constant [6 x i8] c"%.6g\0A\00"
@.puts_int = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@.puts_string = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.puts_true = private unnamed_addr constant [6 x i8] c"true\0A\00"
@.puts_false = private unnamed_addr constant [7 x i8] c"false\0A\00"

define i32 @"puts:float"(double %num){
	%call_return = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.puts_float, i32 0, i32 0), double %num)
	ret i32 %call_return
}

define i32 @"puts:str"(i8* %str){
	%call_return = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.puts_string, i32 0, i32 0), i8* %str)
	ret i32 %call_return
}

define i32 @"puts:int"(i32 %num){
	%call_return = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.puts_int, i32 0, i32 0), i32 %num)
	ret i32 %call_return
}

define i32 @"puts:bool"(i1 %bool){
entry:
	br i1 %bool, label %true, label %false
true:
	%call_return0 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.puts_true, i32 0, i32 0))
	ret i32 %call_return0

false:
	%call_return1 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.puts_false, i32 0, i32 0))
	ret i32 %call_return1
}

declare i32 @printf(i8*, ...)