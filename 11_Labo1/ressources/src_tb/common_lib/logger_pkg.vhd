
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.standard.severity_level;
use STD.textio.all;
use ieee.std_logic_textio.all;

package logger_pkg is

    type logger_t is protected

        procedure log_error(message : string := "");
        procedure log_note(message : string := "");
        procedure log_warning(message : string := "");
        procedure log_failure(message : string := "");

        impure function get_error_counter return integer;
        impure function get_warning_counter return integer;

        procedure write_enable_file;
        procedure write_disable_file;
        procedure set_severity(level: severity_level := note);

        procedure final_report;

    end protected logger_t;

end logger_pkg;


package body logger_pkg is

    type logger_t is protected body

        variable nb_errors : integer := 0;
	      variable nb_warnings : integer := 0;
        variable write_in_file : boolean :=FALSE;
        variable set_severity_level : severity_level := note;
        variable L : line;

        file report_file: text open WRITE_MODE is "../../report_log.txt";

        --------------------------------------------------------
        -- Procedure to call one to set the desired parameters
        --------------------------------------------------------
        -- Enable the writing into a file
        procedure write_enable_file is
        begin
            write_in_file:=TRUE;
        end write_enable_file;

        -- Desable the writing into a file
        procedure write_disable_file is
        begin
            write_in_file:=FALSE;
        end write_disable_file;

        -- Set the severity of the log (note, warning, error, failure)
        procedure set_severity(level: severity_level := note) is
        begin
            set_severity_level := level;
        end set_severity;

        --------------------------------------------------------
        -- Same code for all severity_level
        --------------------------------------------------------
        procedure log(message: string := ""; level: severity_level := note) is
        begin
         report message severity level;
         if write_in_file = TRUE then
           write(L, message);
		       writeline(report_file, L);
         end if;
        end log;

        --------------------------------------------------------
        -- Procedure for each level
        --------------------------------------------------------
        procedure log_error(message: string := "") is
        begin
            if set_severity_level < failure then
              log(message => "[ERROR] " & message, level => error);
            end if;
            --report message severity error;
            nb_errors := nb_errors + 1;
            --report "Nb errors = " & integer'image(nb_errors);
        end log_error;

        procedure log_warning(message: string := "") is
        begin
            if set_severity_level < error then
              log(message => "[WARNING] " & message, level => warning);
            end if;
            --report message severity warning;
            nb_warnings := nb_warnings + 1;
            --report "Nb warnings = " & integer'image(nb_warnings);
        end log_warning;

	      procedure log_note(message: string := "") is
        begin
            if set_severity_level = note then
              log(message => "[NOTE] " & message, level => note);
            end if;
            --report message severity note;
        end log_note;

        --Failure message are allways display because it is then
        --higher problem
	      procedure log_failure(message: string := "") is
        begin
            log(message => "[FAILURE] " & message, level => failure);
            --report message severity failure;
        end log_failure;

        --------------------------------------------------------
        -- Procedure to get both counter if needed
        --------------------------------------------------------
        -- get warning counter
    		impure function get_warning_counter return integer is
    		begin
    			return nb_warnings;
    		end get_warning_counter;

    		-- get error counter
    		impure function get_error_counter return integer is
    		begin
    			return nb_errors;
    		end get_error_counter;

        --------------------------------------------------------
        -- Procedure to report all the errors and warnings
        --------------------------------------------------------
        procedure final_report is
        begin
            report "Nb errors = " & integer'image(nb_errors);
            report "Nb warnings = " & integer'image(nb_warnings);
        end final_report;

    end protected body logger_t;

end logger_pkg;
