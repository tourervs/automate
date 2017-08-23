package main

// Usage:  ./test -cmd="tcpdump -i lo" -count=20
// count - number of lines inside output file

import "fmt"
import "log"
import "os"
import "os/exec"
import "time"
import "errors"
import "flag"
import "strings"
import "io"
import "bufio"
import "path/filepath"

var cmdIsEmpty      = errors.New("cmd is empty")
var countTooShort   = errors.New("count to short")
var parseError      = errors.New("parse error")
var cantOpenNewFile = errors.New("can't open new file")

func main() {

        cmd_line,count,compress,err := parseInput()
        if err != nil { fmt.Printf("Error:%v\nExit\n",err) ; return  }
        _,_ = count,compress

	cmd,err := Command(cmd_line)
        if err != nil { fmt.Printf("Error:%v\nExit\n",err) ; return  }

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		log.Fatal(err)
	}
	if err := cmd.Start(); err != nil {
		log.Fatal(err)
	}

	ch   := make(chan string,100)
	quit := make(chan bool)
        go read(stdout, ch)
        handle(ch, quit, count, compress, cmd)

}

func parseInput()(cmd []string, count int, compress bool ,  err error){

    var cmdLine string

    cmdLinePtr  := flag.String("cmd","","Command to run")
    countPtr    := flag.Int("count",0,"Lines count")
    compressPtr := flag.Bool("compress",false,"Compress")

    flag.Parse()

    if cmdLinePtr  != nil {  cmdLine   = *cmdLinePtr  } else { err = parseError ; return }
    if countPtr    != nil {  count     = *countPtr    } else { err = parseError ; return }
    if compressPtr != nil {  compress  = *compressPtr } else { err = parseError ; return }

    if cmdLine == "" { err = cmdIsEmpty  ; return }
    if count   < 1 { err = countTooShort ; return }

    cmd   = strings.Split(cmdLine," ")

    return

}

func run( cmd []string, count int, compress bool )( err  error ) {

    return

}

func read(rd io.ReadCloser, ch chan string)(){
    //
    lineReader := bufio.NewReader(rd)
    for {
        line,isPrefix,err := lineReader.ReadLine()
        _ = isPrefix
        //fmt.Printf("line: %v\nisPrefix: %v\nerr: %v\n",string(line),isPrefix,err)
        if err== nil {
            ch<-string(line)
        } else {
            break
        }
    }
    close(ch)
    //
}


func handle(ch chan string,quit chan bool, count int , compress bool, cmd *exec.Cmd)(err error){
    //
    var f *os.File
    var cmdName string
    //
    blank   := true
    counter := 0
    //
    for {
        select {
            case s, ok := <-ch:
                    if !ok {
                        break
                    }
                    if blank {
                        // prepare new filename
                        if f!=nil { f.Sync() ;  f.Close() ;  }
                        counter = 0
                        t           := time.Now()
                        timestamp   := t.Format("20060102150405")
                        cmdName     =  "logfile."+timestamp
                        if len(cmd.Args) > 0 {
                            cmdName = cmd.Args[0] + "." + cmdName
                        }
                        f, err = os.Create("./" + cmdName)
                        if err != nil { return cantOpenNewFile }
                        blank = false
                    }
                    _,err = f.WriteString(s+"\n")
                    counter += 1
                    if (counter >= count) || ( err!= nil )  { blank = true }
                    fmt.Printf("\nstring: %v err: %v\n",s,err)
            //case <-quit:
            //        cmd.Process.Kill()
        }
    }
    if f!=nil { f.Sync() ;  ; f.Close() }
    return nil
}

func compress()(){


}

func Command(args []string) (cmd *exec.Cmd,err error) {
    // overwriting existing exec.Command  function 
    var name string
    if len(args) > 0 { name = args[0] }
    cmd = &exec.Cmd{
        Path: name,
        Args: args,
    }
    if filepath.Base(name) == name {
        if lp, err := exec.LookPath(name); err != nil {
            return nil,err
        } else {
            cmd.Path = lp
        }
    }
    return cmd, nil
}
