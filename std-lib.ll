;Standard Library

@.puts_float = private unnamed_addr constant [7 x i8] c"%.11g\0A\00"
@.puts_int = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@.puts_string = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.puts_true = private unnamed_addr constant [6 x i8] c"true\0A\00"
@.puts_false = private unnamed_addr constant [7 x i8] c"false\0A\00"

define i32 @"puts:float"(double %num){
	%call_return = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.puts_float, i32 0, i32 0), double %num)
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

define i32 @"puts:int64"(i64 %num){
	%call_return = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.puts_int, i32 0, i32 0), i64 %num)
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

define i8* @"concatenate:str"(i8* %str1, i8* %str2){
	%str1_length = call i64 @strlen(i8* %str1)
	%new_length = add i64 %str1_length, 1
	%new_string = call i8* @malloc(i64 %new_length)
	%obj_size = call i64 @llvm.objectsize.i64.p0i8(i8* %new_string, i1 false)
	%ret1 = call i8* @__strncat_chk(i8* %new_string, i8* %str1, i64 %new_length, i64 %obj_size)
	%str2_length = call i64 @strlen(i8* %str2)
	%final_length = add i64 %new_length, %str2_length
	%final_string = call i8* @realloc(i8* %new_string, i64 %final_length)	
	%obj_size2 = call i64 @llvm.objectsize.i64.p0i8(i8* %final_string, i1 false)
	%ret2 = call i8* @__strncat_chk(i8* %final_string, i8* %str2, i64 %final_length, i64 %obj_size2)
	ret i8* %final_string
}

declare i32 @printf(i8*, ...)
declare i64 @strlen(i8*)
declare i8* @__strncat_chk(i8*, i8*, i64, i64)
declare i64 @llvm.objectsize.i64.p0i8(i8*, i1)
declare i8* @malloc(i64)
declare i8* @realloc(i8*, i64)
declare void @free(i8*)