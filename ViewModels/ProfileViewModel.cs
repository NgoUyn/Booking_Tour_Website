using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;


namespace Tour_Website.ViewModels
{
    public class ProfileViewModel
    {
        [Display(Name = "Email")]
        public string Email { get; set; }

        [Display(Name = "Họ tên")]
        public string FullName { get; set; }
    }
}