import mqtt

class Chunker

    static var delimiter = bytes().fromstring("Sun")
    static var chunk_len = 20

    var buf
    var callback
    var seen_delim
    var ser

    def init()
        self.callback = / d -> self.publish_data(d)
        self.reset()
        self.ser = serial(17, -1, 57600)
    end

    def set_callback(callback)
        self.callback = callback
    end

    def push(data)

        #print("Data "..data)
        # scan through data to ensure we can find full chunk
        var found_bytes = 0 # how much of a delimiter is found
        var consumed = 0
        for idx: 0..data.size() - 1
            #print("t2|"..idx.."|"..data[idx])
            if data[idx] == self.delimiter[found_bytes] # if this value is part of a delimiter
                #print("t2.1>>")
                found_bytes = found_bytes + 1
                if found_bytes == self.delimiter.size() # we have found a delimiter, discard prior data
                    self.buf = bytes()
                    self.seen_delim = true
                    consumed = idx+1
                    found_bytes = 0
                end
            else
                # cancel any partial delimiter
                found_bytes = 0

                if self.seen_delim && self.buf.size() + idx + 1 - consumed == Chunker.chunk_len # we have a full chunk, callback and discard prior data
                    
                    #reuse internal buffer
                    self.buf..data[consumed..idx]
                    self.callback(self.buf)
                    self.buf = bytes()
                    consumed = idx+1

                    found_bytes = 0
                end
            end   
        end 


        if consumed < data.size()
            self.buf = data[consumed .. data.size()]
        end 
    end

    def reset()
        self.buf = bytes()
        self.seen_delim = false
    end


    def every_second()
        var msg = self.ser.read()

        if(msg.size() > 0)
            self.push(msg)
        end
    end

    def publish_data(data)
        mqtt.publish("stat/sunswitch/temp", ""..data.get(8,1))
    end
end

var c = Chunker()
tasmota.add_driver(c)
