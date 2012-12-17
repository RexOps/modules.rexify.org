(function() {

   $(document).ready(function() {

      $("#contrib_link").click(function() {
         if($("#contribute_page").css("display") == "block") {
            $("#contribute_page").hide();
         }
         else {
            $("#help_page").hide();
            $("#contribute_page").show();
         }
      });

      $("#help_link").click(function() {
         if($("#help_page").css("display") == "block") {
            $("#help_page").hide();
         }
         else {
            $("#contribute_page").hide();
            $("#help_page").show();
         }
      });

   });

})();
