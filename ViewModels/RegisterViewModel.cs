using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace Tour_Website.ViewModels
{
    public class RegisterViewModel
    {
        [Required]
        [Display(Name = "Full name")]
        public string UserName { get; set; }

        [Required]
        [EmailAddress]
        public string Email { get; set; }

        [Required]
        [StringLength(100, MinimumLength = 6)]
        [DataType(DataType.Password)]
        public string Password { get; set; }

        [Required]
        [DataType(DataType.Password)]
        [Compare("Password")]
        [Display(Name = "Confirm password")]
        public string ConfirmPassword { get; set; }

        [Required]
        [DataType(DataType.Date)]
        [Display(Name = "Ngày sinh")]
        public DateTime? BirthDate { get; set; }

        [Required]
        [Phone]
        [Display(Name = "Số điện thoại")]
        public string Phone { get; set; }

        [Required]
        [Display(Name = "Họ và tên")]
        public string FullName { get; set; }
    }
}
