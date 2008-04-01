#
#--
# Copyright (c) 2005-2008, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#++
#

#
# "hecho en Costa Rica"
#
# john.mettraux@openwfe.org
#

require 'date'
#require 'parsedate'


module Rufus

    #TIME_FORMAT = "%Y-%m-%d %H:%M:%S"

    #
    # Returns the current time as an ISO date string
    #
    def Rufus.now

        to_iso8601_date(Time.new())
    end

    #
    # As the name implies.
    #
    def Rufus.to_iso8601_date (date)

        if date.kind_of? Float 
            date = to_datetime(Time.at(date))
        elsif date.kind_of? Time
            date = to_datetime(date)
        elsif not date.kind_of? Date
            date = DateTime.parse(date)
        end

        s = date.to_s # this is costly
        s[10] = " "

        s
    end

    #
    # the old method we used to generate our ISO datetime strings
    #
    def Rufus.time_to_iso8601_date (time)

        s = time.getutc().strftime(TIME_FORMAT)
        o = time.utc_offset / 3600
        o = o.to_s + "00"
        o = "0" + o if o.length < 4
        o = "+" + o unless o[0..1] == '-'

        s + " " + o.to_s
    end

    #
    # Returns a Ruby time
    #
    def Rufus.to_ruby_time (iso_date)

        DateTime.parse(iso_date)
    end

    #def Rufus.parse_date (date)
    #end

    #
    # equivalent to java.lang.System.currentTimeMillis()
    #
    def Rufus.current_time_millis

        (Time.new.to_f * 1000).to_i
    end

    #
    # Turns a string like '1m10s' into a float like '70.0', more formally,
    # turns a time duration expressed as a string into a Float instance 
    # (millisecond count).
    #
    # w -> week
    # d -> day
    # h -> hour
    # m -> minute
    # s -> second
    # M -> month
    # y -> year
    # 'nada' -> millisecond
    #
    # Some examples :
    #
    #   Rufus.parse_time_string "500"        # => 0.5
    #   Rufus.parse_time_string "1000"       # => 1.0
    #   Rufus.parse_time_string "1h"         # => 3600.0
    #   Rufus.parse_time_string "1h10s"      # => 3610.0
    #   Rufus.parse_time_string "1w2d"       # => 777600.0
    #
    def Rufus.parse_time_string (string)

        string = string.strip

        index = -1
        result = 0.0

        number = ""

        loop do

            index = index + 1

            if index >= string.length
                result = result + (Float(number) / 1000.0) if number.length > 0
                break
            end

            c = string[index, 1]

            #if is_digit?(c)
            if (c >= "0" and c <= "9")
                number = number + c
                next
            end

            value = Integer(number)
            number = ""

            multiplier = DURATIONS[c]

            raise "unknown time char '#{c}'" \
                if not multiplier

            result = result + (value * multiplier)
        end

        result
    end

    class << self
        alias_method :parse_duration_string, :parse_time_string
    end

    #
    # Returns true if the character c is a digit
    #
    # (probably better served by a regex)
    #
    def Rufus.is_digit? (c)

        return false if not c.kind_of?(String)
        return false if c.length > 1
        (c >= "0" and c <= "9")
    end

    #
    # conversion methods between Date[Time] and Time

    #
    # Ruby Cookbook 1st edition p.111
    # http://www.oreilly.com/catalog/rubyckbk/
    # a must
    #

    #
    # converts a Time instance to a DateTime one
    #
    def Rufus.to_datetime (time)

        s = time.sec + Rational(time.usec, 10**6)
        o = Rational(time.utc_offset, 3600 * 24)

        begin

            DateTime.new(
                time.year, 
                time.month, 
                time.day, 
                time.hour, 
                time.min, 
                s, 
                o)

        rescue Exception => e

            DateTime.new(
                time.year, 
                time.month, 
                time.day, 
                time.hour, 
                time.min, 
                time.sec, 
                time.utc_offset)
        end
    end

    def Rufus.to_gm_time (dtime)

        to_ttime(dtime.new_offset, :gm)
    end

    def Rufus.to_local_time (dtime)

        to_ttime(dtime.new_offset(DateTime.now.offset-offset), :local)
    end

    def Rufus.to_ttime (d, method)

        usec = (d.sec_fraction * 3600 * 24 * (10**6)).to_i
        Time.send(method, d.year, d.month, d.day, d.hour, d.min, d.sec, usec)
    end

    #
    # Turns a number of seconds into a a time string
    #
    #     Rufus.to_duration_string 0                    # => '0s'
    #     Rufus.to_duration_string 60                   # => '1m'
    #     Rufus.to_duration_string 3661                 # => '1h1m1s'
    #     Rufus.to_duration_string 7 * 24 * 3600        # => '1w'
    #     Rufus.to_duration_string 30 * 24 * 3600 + 1   # => "4w2d1s"
    #
    # It goes from seconds to the year. Months are not counted (as they
    # are of variable length). Weeks are counted.
    #
    # For 30 days months to be counted, the second parameter of this
    # method can be set to true.
    #
    #     Rufus.to_time_string 30 * 24 * 3600 + 1, true   # => "1M1s"
    #
    # (to_time_string is an alias for to_duration_string)
    #
    # If a Float value is passed, milliseconds will be displayed without
    # 'marker'
    #
    #     Rufus.to_duration_string 0.051                         # =>"51"
    #     Rufus.to_duration_string 7.051                         # =>"7s51"
    #     Rufus.to_duration_string 0.120 + 30 * 24 * 3600 + 1    # =>"4w2d1s120"
    #
    # (this behaviour mirrors the one found for parse_time_string()).
    #
    # Options are :
    #
    # * :months, if set to true, months (M) of 30 days will be taken into
    #   account when building up the result
    # * :drop_seconds, if set to true, seconds and milliseconds will be trimmed
    #   from the result
    #
    def Rufus.to_duration_string (seconds, options={})

        return (options[:drop_seconds] ? '0m' : '0s') if seconds <= 0

        h = to_duration_hash seconds, options

        s = DU_KEYS.inject("") do |r, key|
            count = h[key]
            count = nil if count == 0
            r << "#{count}#{key}" if count
            r
        end

        ms = h[:ms]
        s << ms.to_s if ms

        s
    end

    class << self
        alias_method :to_time_string, :to_duration_string
    end

    #
    # Turns a number of seconds (integer or Float) into a hash like in :
    #
    #     Rufus.to_duration_hash 0.051                         
    #         # => { :ms => "51" }
    #     Rufus.to_duration_hash 7.051
    #         # => { :s => 7, :ms => "51" }
    #     Rufus.to_duration_hash 0.120 + 30 * 24 * 3600 + 1
    #         # => { :w => 4, :d => 2, :s => 1, :ms => "120" }
    #
    # This method is used by to_duration_string (to_time_string) behind
    # the scene.
    #
    # Options are :
    #
    # * :months, if set to true, months (M) of 30 days will be taken into
    #   account when building up the result
    # * :drop_seconds, if set to true, seconds and milliseconds will be trimmed
    #   from the result
    #
    def Rufus.to_duration_hash (seconds, options={})

        h = {}

        if seconds.is_a?(Float)
            h[:ms] = (seconds % 1 * 1000).to_i
            seconds = seconds.to_i
        end

        if options[:drop_seconds]
            h.delete :ms
            seconds = (seconds - seconds % 60)
        end

        durations = options[:months] ? DURATIONS2M : DURATIONS2

        durations.each do |key, duration|

            count = seconds / duration
            seconds = seconds % duration

            h[key.to_sym] = count if count > 0
        end

        h
    end

    protected

        DURATIONS2M = [
            [ "y", 365 * 24 * 3600 ],
            [ "M", 30 * 24 * 3600 ],
            [ "w", 7 * 24 * 3600 ],
            [ "d", 24 * 3600 ],
            [ "h", 3600 ],
            [ "m", 60 ],
            [ "s", 1 ]
        ]
        DURATIONS2 = DURATIONS2M.dup
        DURATIONS2.delete_at 1

        DURATIONS = DURATIONS2M.inject({}) do |r, (k, v)|
            r[k] = v
            r
        end

        DU_KEYS = DURATIONS2M.collect { |k, v| k.to_sym }

end

