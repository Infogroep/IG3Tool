module Gtk
	class TextView
		def text
			buffer.text
		end

		def text=(str)
			buffer.text = str
		end
	end
end

class String

	def starts_with?(str)
		self.index( str ) == 0
	end

	def ends_with?(str)
		self.rindex( str ) == self.length - str.length
	end

	def to_c
		self.to_f.to_c
	end

	def from_c
		self.to_f.from_c
	end

  def smaller(l=75)
    if self.size > l
      self[0..l] + "..."
		else
			self
    end
  end

	def to_boolean
		return true if (self == "t" or self.to_i != 0)
		false
	end

end

class Numeric
  def to_c
    (self.to_f * 100).round.to_i
  end

  def from_c
    (self.to_f / 100)
  end

  def to_b
    return (not (self.zero?))
  end
end

class Hash
	# File facets/hash/new.rb, line 44
  def self.zipnew(keys,values) # or some better name
    h = {}
    keys.size.times{ |i| h[ keys[i] ] = values[i] }
    h
  end
	# File facets/hash/keyize.rb, line 49
  def normalize_keys!( &block )
    keys.each{ |k|
      nk = block[k]
      self[nk]=delete(k) if nk
    }
    self
  end
end

class Time
	# bepaling van de week van het academiejaar
	def week
		t = start_werkjaar(Time.werkjaar)
		return 1 + ((self - t) / (86400*7)).to_int
	end

	# we bepalen de start van het werkjaar (laatste ma van sept)
	def self.start_werkjaar(jaar)
		t = Time.mktime(jaar, 9, 30)
		t = t - 86400 until t.wday == 1
		t
	end

	def self.werkjaar
		t = Time.now()
		t > start_werkjaar(t.year) ? t.year : t.year - 1
	end
end
