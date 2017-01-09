; ModuleID = 'test'
source_filename = "test"

; Declare the string constant as a global constant.
@.str = private unnamed_addr constant [12 x i8] c"hello world\00"
@.str2 = private unnamed_addr constant [13 x i8] c"hello world2\00"

define i32 @main() {
main_body:
  %number = alloca i32
  br i1 false, label %if_block, label %else_block

if_block:                                         ; preds = %main_body
  %str1 = getelementptr [12 x i8], [12 x i8]* @.str, i64 0, i64 0
  call i32 @puts(i8* %str1)
  store i32 2, i32* %number
  br label %return_block

else_block:                                       ; preds = %main_body
  %str2 = getelementptr [13 x i8], [13 x i8]* @.str2, i64 0, i64 0
  call i32 @puts(i8* %str2)
  store i32 5, i32* %number
  br label %return_block

return_block:                                     ; preds = %else_block, %if_block
  %ret_value = load i32, i32* %number
  ret i32 %ret_value
}

declare i32 @puts(i8*)
