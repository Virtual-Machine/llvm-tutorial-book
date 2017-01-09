; ModuleID = 'test'
source_filename = "proposal-1"

@.itoa = internal constant [3 x i8] c"%d\00"

define i32 @main() {
entry:
        %four = alloca i32
        store i32 4, i32* %four
        %stringb = alloca [79 x i8]
        %bufferp = getelementptr [79 x i8], [79 x i8]* %stringb, i32 0, i32 0
        %itoa = getelementptr [3 x i8], [3 x i8]* @.itoa, i32 0, i64 0
        
        ; puts four
        %fourv = load i32, i32* %four

        ; print four as string
        call i32 (i8*, i32, i64, i8*, ...) @__sprintf_chk(i8* %bufferp, i32 0, i64 79, i8* %itoa, i32 %fourv)            
        call i32 @puts( i8* %bufferp ) nounwind

        ; puts 10 < 6
        %value = icmp ult i32 6, 10
        %upc = zext i1 %value to i32
        
        call i32 (i8*, i32, i64, i8*, ...) @__sprintf_chk(i8* %bufferp, i32 0, i64 79, i8* %itoa, i32 %upc)            
        call i32 @puts( i8* %bufferp ) nounwind

        ret i32 0
}

declare i32 @__sprintf_chk(i8*, i32, i64, i8*, ...) #1

declare i32 @puts(i8*)
