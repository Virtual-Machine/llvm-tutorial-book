; ModuleID = 'std-lib.ll'
source_filename = "std-lib.ll"

@.puts_float = private unnamed_addr constant [7 x i8] c"%.11g\0A\00"
@.puts_int = private unnamed_addr constant [4 x i8] c"%d\0A\00"
@.puts_string = private unnamed_addr constant [4 x i8] c"%s\0A\00"
@.puts_true = private unnamed_addr constant [6 x i8] c"true\0A\00"
@.puts_false = private unnamed_addr constant [7 x i8] c"false\0A\00"

; Function Attrs: nounwind
define i32 @"puts:float"(double %num) local_unnamed_addr #0 {
  %call_return = tail call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.puts_float, i64 0, i64 0), double %num)
  ret i32 %call_return
}

; Function Attrs: nounwind
define i32 @"puts:str"(i8* %str) local_unnamed_addr #0 {
  %call_return = tail call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.puts_string, i64 0, i64 0), i8* %str)
  ret i32 %call_return
}

; Function Attrs: nounwind
define i32 @"puts:int"(i32 %num) local_unnamed_addr #0 {
  %call_return = tail call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.puts_int, i64 0, i64 0), i32 %num)
  ret i32 %call_return
}

; Function Attrs: nounwind
define i32 @"puts:int64"(i64 %num) local_unnamed_addr #0 {
  %call_return = tail call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.puts_int, i64 0, i64 0), i64 %num)
  ret i32 %call_return
}

; Function Attrs: nounwind
define i32 @"puts:bool"(i1 %bool) local_unnamed_addr #0 {
entry:
  br i1 %bool, label %true, label %false

true:                                             ; preds = %entry
  %call_return0 = tail call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.puts_true, i64 0, i64 0))
  ret i32 %call_return0

false:                                            ; preds = %entry
  %call_return1 = tail call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.puts_false, i64 0, i64 0))
  ret i32 %call_return1
}

define i8* @"concatenate:str"(i8* %str1, i8* %str2) local_unnamed_addr {
  %str1_length = tail call i64 @strlen(i8* %str1)
  %new_length = add i64 %str1_length, 1
  %new_string = tail call i8* @malloc(i64 %new_length)
  %obj_size = tail call i64 @llvm.objectsize.i64.p0i8(i8* %new_string, i1 false)
  %ret1 = tail call i8* @__strncat_chk(i8* %new_string, i8* %str1, i64 %new_length, i64 %obj_size)
  %str2_length = tail call i64 @strlen(i8* %str2)
  %final_length = add i64 %str2_length, %new_length
  %final_string = tail call i8* @realloc(i8* %new_string, i64 %final_length)
  %obj_size2 = tail call i64 @llvm.objectsize.i64.p0i8(i8* %final_string, i1 false)
  %ret2 = tail call i8* @__strncat_chk(i8* %final_string, i8* %str2, i64 %final_length, i64 %obj_size2)
  ret i8* %final_string
}

define i8* @"repetition:str"(i8* %str, i32 %rep) local_unnamed_addr {
header:
  %rep64 = zext i32 %rep to i64
  %str_length = tail call i64 @strlen(i8* %str)
  %final_length = add i64 %str_length, 1
  %final_string = tail call i8* @malloc(i64 %final_length)
  %obj_size = tail call i64 @llvm.objectsize.i64.p0i8(i8* %final_string, i1 false)
  br label %loop_body

loop_body:                                        ; preds = %loop_body, %header
  %rep1.0 = phi i64 [ %rep64, %header ], [ %rep3, %loop_body ]
  %ret1 = tail call i8* @__strncat_chk(i8* %final_string, i8* %str, i64 %final_length, i64 %obj_size)
  %rep3 = add i64 %rep1.0, -1
  %is_zero = icmp eq i64 %rep3, 0
  br i1 %is_zero, label %loop_footer, label %loop_body

loop_footer:                                      ; preds = %loop_body
  ret i8* %final_string
}

; Function Attrs: nounwind
declare i32 @printf(i8* nocapture readonly, ...) local_unnamed_addr #0

; Function Attrs: nounwind readonly
declare i64 @strlen(i8* nocapture) local_unnamed_addr #1

declare i8* @__strncat_chk(i8*, i8*, i64, i64) local_unnamed_addr

; Function Attrs: nounwind readnone
declare i64 @llvm.objectsize.i64.p0i8(i8*, i1) #2

; Function Attrs: nounwind
declare noalias i8* @malloc(i64) local_unnamed_addr #0

; Function Attrs: nounwind
declare noalias i8* @realloc(i8* nocapture, i64) local_unnamed_addr #0

attributes #0 = { nounwind }
attributes #1 = { nounwind readonly }
attributes #2 = { nounwind readnone }
