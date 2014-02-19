require 'net/smtp'

module Ig3tool

    class SalesWindow < GladeHelper
        MENU_PATH = ["Sales", "Sales"]
        ICON = "emblem-sales.png"

        def initialize
            super("sales.glade")
            @status = "non member"

            @standard_beep = "biep3.wav"

            @statushash = {0 => "non member", 1 => "debugger", 2 => "member"}
            @statushashi = @statushash.invert

            # init items
            @saldo_label = _get_widget("saldo_label")
            @saldo = _get_widget("saldo")

            @items = _get_widget("list")
            @items.model = Gtk::ListStore.new(Integer, String, Float, Object, String)
            r = Gtk::CellRendererText.new
            @items.insert_column(-1, "Aantal",  r, :text => 0)
            @items.insert_column(-1, "Product", r, :text => 1)
            @items.insert_column(-1, "Prijs",   r, :text => 2)
            @member_id = @glade.get_widget("member_id")

            @window.show

            make_debugger_combo(_get_widget("debugger"), @window)
            make_eval_widget @glade.get_widget("count"), 1

            toggle_saldo_label(false)
        end

        def focus_smartzap
            _get_widget("smartzap").grab_focus
        end

        def set_saldo(username)
            begin
                i = $client.interne(username)
                @saldo.text = i.saldo.from_c.to_s
            rescue Exception => e
                @saldo.text = e.message
            end
        end

        def get_saldo(username)
            begin
                i = $client.interne(username)
                return i.saldo.from_c
            rescue Exception => e
                Pass
            end
        end
    
        def toggle_saldo_label(bool=nil)
            if bool.nil?
                if @saldo_label.text.empty?
                    @saldo_label.text = "Saldo:"
                else
                    @saldo_label.text = ""
                    @saldo.text = ""
                end
            else
                if bool
                    @saldo_label.text = "Saldo:"
                else
                    @saldo_label.text = ""
                    @saldo.text = ""
                end
            end
        end
    
        def play_standard_sound(debugger)
            case debugger
                when "rtytgat": play("lolplaybutton.wav")
                when "rivmeche": play("lolplaybutton.wav")
                when "jalemait": play("beepbeep.mp3")
                when "fdevrien": play("beepbeep.mp3")
                when "jadebie": play("biep3.wav")
                when "kwpardon": play("girlsigh.wav")
                when "rmatthij": play(enumerateSounds(File.join("rmatthij","scan","*")).choice)
                else play("biep3.wav")
            end
        end

        def play_debugger_sound(debugger)
            case debugger
                when "tetten": play("tetten.wav")
                when "rdewaele": play("yeahbaby.wav")
                when "nvgeele": play("spanish2.wav")
                when "bderooms": play("justice1.wav")
                when "yocoppen": play("koekje.wav")
                when "hdebondt": play("pika.wav")
                when "kwpardon": play("girlsigh.wav")
                when "rtytgat": play("lolbuttonandgreetings.wav")
                when "rivmeche": play("lolbuttonandgreetings.wav")
                when "tstrickx": play("scout2.wav")
                when "fdevrien": play("r2d2.mp3")
                when "khendric": play("modem.mp3")
                when "ayvercru": play("yesmaster.mp3")
                when "jalemait": play("Shazam.mp3")
                when "rmatthij": play(enumerateSounds(File.join("rmatthij","select","*")).choice)
                else play("biep3.wav")
            end
        end

        def play_kaching_sound(debugger)
            play("kaching.wav")
        end

        def play_scribble_sound(debugger)
            if get_saldo(debugger) < -20.0
                play("dollar.mp3")
            else
                case debugger
                    when "graerts": play("miley_yeah.wav")
                    when "rdewaele": play("fart.wav")
                    when "yocoppen": play("letsgo.wav")
                    when "tstrickx": play("scout1.wav")
                    when "rtytgat": play("lolbuttonandreadytoplay.wav")
                    when "rivmeche": play("lolbuttonandreadytoplay.wav")
                    when "kwpardon": play("girlsigh.wav")
                    when "khendric": play("befehl.mp3")
                    when "fdevrien": play("alright.mp3")
                    when "ayvercru": play("as_you_wish.mp3")
                    when "jalemait": play("Thankyou.mp3")
                    when "rmatthij": play(enumerateSounds(File.join("rmatthij","scribble","*")).choice)
                    when "lavholsb": play("Larsje.wav")
                    else play("scribble.wav")
                end
            end
        end

        def play_clear_sound(debugger)
            play_standard_sound(debugger)
        end

        def smartzap_activate
            value = _get_widget("smartzap").text
            value.strip!
            _get_widget("smartzap").text = ""

            case value
            when "non member"
                @target = nil
                @status = "non member"
                toggle_saldo_label(false)
                @member_id.active = @statushashi[@status]
                play_standard_sound(@debugger)
                return
            
            when "member"
                @target = nil
                @status = "member"
                toggle_saldo_label(false)
                @member_id.active = @statushashi[@status]
                play_standard_sound(@debugger)
                return

            when "kaching"
                _kaching
                @items.model.clear
                return

            when "scribble"
                _scribble
                @items.model.clear
                return

            when "clear"
                play_clear_sound(@debugger)
                @items.model.clear
                return

                # is het een debugger?
            when /^[a-z-]/i
                wanted = {"username", value, "status", "debugger"}
                pers = $client.person_lookup(wanted)

                unless pers.empty?
                    play_debugger_sound(value)

                    pers = pers.first

                    @status = "debugger"
                    @target = @debugger = pers.username
                    toggle_saldo_label(true)
                    set_saldo(@debugger)

                    _get_widget("debugger").model.each do |m, p, i|
                        if i[1] == @target
                            _get_widget("debugger").active_iter = i
                            @member_id.active = @statushashi[@status]
                            return
                        end
                    end if _get_widget("debugger").model
                end 
            end


            # lidkaart magic: eg scan 000708XXXXX -> lidkaart
            begin
                jaar = Time.werkjaar % 100
                lidkaartx = sprintf("^00%02d%02d", jaar, jaar+1).to_re
                if value =~ lidkaartx # yay! fascets! (fascisme?)
                    begin 
                        $client.person_member(value)
                        # als deze lidkaart overeenkomt met een member => 
                        # zet value op member
                        @target = value
                        @status = "member"
                        @member_id.active = @statushashi[@status]
                        puts "member found.."
                    rescue Ig3tool::NotAMember => e
                        # alst gene member is => verkoop een lidkaart :)
                        value = "lidkaart"
                    end
                    play_standard_sound(@debugger)
                end
            end


            puts "not anything above"

            # is het een product?
            begin
                prod = $client.product_lookup(value)
                if prod.name.downcase == "void"
                    play("retards")
                    dialog = Gtk::MessageDialog.new(
                        @window,
                        Gtk::Dialog::DESTROY_WITH_PARENT,
                        Gtk::MessageDialog::ERROR,
                        Gtk::MessageDialog::BUTTONS_OK,
                        "Use the zapblad!")
                    dialog.title = "Rrrrr ... retard!"
                    dialog.run{|r|}
                    dialog.destroy
#                    self.use_zapblad
                    return
                end
                # speak(prod.name) # SPEAK OR DIE!
                qty  = _get_widget("count").text.to_i
                puts prod
                _add_product(prod, qty)
                play_standard_sound(@debugger)
                return
            rescue Exception => e
                warn "Look mom, it's an airplane!"
                warn "#{e.class} - #{e.message}"
            end
            # het is een vliegtuig!
        end

#        def use_zapblad
#            from = "igtool@infogroep.be"
#            from_alias = "the imps"
#            to = "#{@debugger}@infogroep.be"
#            to_alias = "Noob"
#            subj = "ZAPBLAD GEBRUIKEN ADDABAKKES!"
#            msg = <<BOE
#Date: #{Time.new.rfc2822}
#From: #{from_alias} <#{from}>
#To: #{to_alias} <#{to}>
#Subject: #{subj}     
#
#Dag stout kindje
#
#Leer het zapblad te gebruiken!
#
#Bedankt en veel zachte kusjes,
#Ben en zijn kudde imps.
#BOE
#                    begin
#                            Net::SMTP.start('igwe.vub.ac.be') do |smtp|
#                                    smtp.send_message msg, from, to
#                            end
#                    rescue TimeoutError
#                            warn "ERROR: failed to send mail: timeout sending email"
#                    rescue Net::SMTPFatalError => e
#                            warn "ERROR: SMTP error #{e}"
#                    end
#        end

        def debugger_changed
            @status = "debugger"
            iter = _get_widget("debugger").active_iter
            unless iter.nil?
                @target = @debugger = iter[1]
                @member_id.active = @statushashi[@status]
            end
            toggle_saldo_label(true)
            set_saldo(@debugger)
        end

        def member_changed
            puts "member_changed"
            chosen = @member_id.active_text.strip
            @target = nil
            
            case chosen
                when "non member"
                    @status = "non member"
                    toggle_saldo_label(false)

                when "debugger"
                    @target = @debugger = _get_widget("debugger").active_iter[1]
                    @status = "debugger"
                    toggle_saldo_label(true)
                    set_saldo(@debugger)

                else # member
                    toggle_saldo_label(false)
                    begin
                        memb = $client.person_member(chosen)

                        @target = chosen
                        @status = "member"
                        puts "member found.."
                    rescue NotAMember => e
                        puts "not a member..."
                    end
            end
        end

        def delete_clicked
            sel = @items.selection.selected
            @items.model.remove(sel) if sel
        end

        def price_entries_changed
            paid   = _get_widget("paid").text.to_f
            total  = _get_widget("total").text.to_f

            change = paid - total
            change = 0 if change < 0

            _get_widget("change").text = sprintf("%.2f", change)
        end

        def scribble_clicked
            _scribble
            @items.model.clear
        end

        def kaching_clicked
            begin
            _kaching
            @items.model.clear
            rescue Exception => e
                puts "ERROR: #{e.message}"
            end
        end
        
        def bewijs
            puts "NYI"
        end

        def clear_clicked
      play("clear")
            @items.model.clear
            _update_total
      toggle_saldo_label(false)
      @member_id.active = 0
            focus_smartzap()
        end

        alias_method :count_activate, :smartzap_activate

        private
        def _get_items
            products = []
            @items.model.each do |model, path, row|
                products.push([row[3].barcode,row[0]])
            end
            products
        end

        def _get_items_with_status
            products = {}
            @items.model.each do |model, path, row|
                recip = products[row[4]] ||= []
                recip.push([row[3].barcode,row[0]])
            end
            products
        end

        def _scribble
            unless @status == "debugger"
                warn "not a debugger"
                return
            end

            items = _get_items

            return if items.empty?
            params = { "debugger" => @debugger,
                       "items"    => items }

            begin
                $client.scribble! params
                clear_clicked
                play_scribble_sound(@debugger)
            rescue Exception => e
                puts "Error: #{$!}"
            end
        end

        def _kaching
            items = _get_items_with_status

            items.each do |status, items|

                params = { "debugger" => @debugger, 
                           "items"    => items,
                           "status"   => status }

                begin
                    $client.kaching! params
                    clear_clicked
                    play_kaching_sound(@debugger)
                rescue Exception => e
                    puts "Error: #{$!}"
                end
            end
        end

        def _add_product(prod, qty)
            qty = qty.to_i
            return if qty < 1

            # zoek eerst naar een bestaande entry voor prod
            found = nil
            @items.model.each do |model, path, row|
                found = row if row[3].barcode == prod.barcode and @status == row[4]
            end

            if found
                oldqty = found[0]
                found[0] += qty
                found[2] = found[2] * (oldqty+qty)/oldqty
            else
                row = @items.model.append
                row[0] = qty
                row[1] = prod.name
                row[2] = qty * prod.send(_price).to_f / 100
                row[3] = prod
                row[4] = @status
            end

            _get_widget("count").text = "1"
            _update_total
        end

        def _price
            case @status
            when "debugger"
                :dprice

            when "member"
                :mprice

            else
                :nmprice
            end
        end

        def _update_total
            total = 0.0
            @items.model.each { |m, p, r| total += r[2].to_f }
            _get_widget("total").text = sprintf "%.2f", total
        end

    end

    register_window(SalesWindow)

end
