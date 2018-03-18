
library common_lib;
use common_lib.logger_pkg;

package comparator_pkg is
    generic(
        type data_type;
        function data_to_string(data : data_type) return string
    );

    procedure compare(logger : inout logger_pkg.logger_t; value1 : data_type; value2: data_type);

    function compare(value1 : data_type; value2: data_type) return boolean;

end comparator_pkg;

package body comparator_pkg is

    procedure compare(logger: inout logger_pkg.logger_t; value1 : data_type; value2: data_type) is
    begin
        if compare(value1, value2) then
            logger.log_error("Failed: " & data_to_string(value1) & " and " & data_to_string(value2) & " are not the same");
        end if;
    end compare;


    function compare(value1 : data_type; value2: data_type) return boolean is
    begin
        if (value1 /= value2) then
            return true;
        else
            return false;
        end if;
    end compare;

end comparator_pkg;
