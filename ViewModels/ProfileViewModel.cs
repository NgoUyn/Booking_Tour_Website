using System;
using System.ComponentModel.DataAnnotations;

namespace Tour_Website.ViewModels
{
    public class ProfileViewModel
    {
        [Display(Name = "Email")]
        [EmailAddress]
        public string Email { get; set; }

        [Display(Name = "Họ tên")]
        [Required]
        public string FullName { get; set; }

        [Display(Name = "Số điện thoại")]
        [Phone]
        public string Phone { get; set; }

        [Display(Name = "Ngày sinh")]
        [DataType(DataType.Date)]
        public DateTime? BirthDate { get; set; }

        [DataType(DataType.Password)]
        [Display(Name = "Mật khẩu hiện tại")]
        public string CurrentPassword { get; set; }

        [DataType(DataType.Password)]
        [Display(Name = "Mật khẩu mới")]
        [StringLength(100, MinimumLength = 6)]
        public string NewPassword { get; set; }

        [DataType(DataType.Password)]
        [Display(Name = "Xác nhận mật khẩu mới")]
        [Compare("NewPassword", ErrorMessage = "Mật khẩu xác nhận không khớp.")]
        public string ConfirmPassword { get; set; }
    }
}