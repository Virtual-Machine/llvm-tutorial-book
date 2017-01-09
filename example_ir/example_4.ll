; ModuleID = 'module_name'

@number = global i32 10
@str = private unnamed_addr constant [7 x i8] c"Johnny\00"

define i32 @main() {
main_body:
  %str_call = call i32 @puts(i8* getelementptr inbounds ([7 x i8], [7 x i8]* @str, i32 0, i32 0))
  %0 = load i32, i32* @number
  ret i32 %0
}

declare i32 @puts(i8*)
