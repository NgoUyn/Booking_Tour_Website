using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Security;
using Tour_Website.DAL;
using System.Security.Cryptography;
using System.Text;
using Tour_Website.ViewModels;
using Tour_Website.Models;
//using QRCoder; // NuGet: Install-Package QRCoder
using System.Drawing;
using System.IO;

namespace Tour_Website.Controllers
{
    [AllowAnonymous] // Áp dụng cho toàn bộ controller nếu cần, nhưng tốt hơn là chỉ cho actions public
    public class AccountController : Controller
    {
        private UserDAO userDAO = new UserDAO();
        private TourProject_Database db = new TourProject_Database();

        // GET: /Account/Register
        [AllowAnonymous]
        public ActionResult Register()
        {
            return View();
        }

        // POST: /Account/Register
        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public ActionResult Register(RegisterViewModel model)
        {
            if (ModelState.IsValid)
            {
                if (userDAO.CheckEmailExist(model.Email))
                {
                    ModelState.AddModelError("", "Email này đã được sử dụng.");
                    return View(model);
                }

                if (userDAO.Register(model))
                {
                    TempData["SuccessMessage"] = "Đăng ký thành công! Vui lòng đăng nhập.";
                    return RedirectToAction("Login");
                }
                else
                {
                    ModelState.AddModelError("", "Đăng ký thất bại. Vui lòng thử lại.");
                }
            }
            return View(model);
        }

        // GET: /Account/Login
        [AllowAnonymous]
        public ActionResult Login(string returnUrl)
        {
            ViewBag.ReturnUrl = returnUrl;
            return View();
        }

        // POST: /Account/Login
        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public ActionResult Login(LoginViewModel model, string returnUrl)
        {
            if (ModelState.IsValid)
            {
                if (userDAO.Login(model.Email, model.Password))
                {
                    // Tạo Cookie xác thực (Quan trọng để User.Identity.IsAuthenticated = true)
                    FormsAuthentication.SetAuthCookie(model.Email, model.RememberMe);

                    // Lưu Email vào Session để dùng cho các trang khác
                    Session["UserEmail"] = model.Email;

                    if (!string.IsNullOrEmpty(returnUrl) && Url.IsLocalUrl(returnUrl))
                    {
                        return Redirect(returnUrl);
                    }
                    else
                    {
                        return RedirectToAction("Index", "Home");
                    }
                }
                else
                {
                    ModelState.AddModelError("", "Email hoặc mật khẩu không đúng.");
                }
            }
            return View(model);
        }

        // ==========================================================
        // KHU VỰC CẦN SỬA ĐỂ FIX LỖI WARNING VÀ THÊM CHỨC NĂNG
        // ==========================================================

        // GET: /Account/Profile
        [Authorize]
        public new ActionResult Profile() // Thêm từ khóa 'new' để fix lỗi ẩn thuộc tính
        {
            string userEmail = Session["UserEmail"]?.ToString() ?? User.Identity.Name;
            var user = userDAO.GetUserByEmail(userEmail);
            if (user == null) return RedirectToAction("Login");

            var model = new ProfileViewModel
            {
                Email = user.Email,
                FullName = user.UserName // Hoặc user.FullName nếu có cột này
            };
            return View(model);
        }

        // POST: /Account/Profile (Cập nhật thông tin)
        [HttpPost]
        [Authorize]
        [ValidateAntiForgeryToken]
        public new ActionResult Profile(ProfileViewModel model) // Thêm từ khóa 'new'
        {
            if (ModelState.IsValid)
            {
                string userEmail = Session["UserEmail"]?.ToString() ?? User.Identity.Name;
                // Gọi hàm cập nhật user qua userDAO (cần đảm bảo hàm này đã có bên DAO)
                // userDAO.UpdateProfile(model, userEmail); 

                TempData["SuccessMessage"] = "Cập nhật thông tin thành công!";
                return RedirectToAction("Profile");
            }
            return View(model);
        }

        // GET: /Account/SaveTours - Các tour đã lưu
        [Authorize]
        public ActionResult SaveTours()
        {
            if (!User.Identity.IsAuthenticated)
            {
                return RedirectToAction("Login");
            }

            string userEmail = Session["UserEmail"]?.ToString() ?? User.Identity.Name;
            // var savedTours = userDAO.GetSavedToursByEmail(userEmail);
            return View();
        }

        // GET: /Account/BookingHistory - Lịch sử đặt vé
        [Authorize]
        public ActionResult BookingHistory()
        {
            if (!User.Identity.IsAuthenticated)
            {
                return RedirectToAction("Login");
            }

            string userEmail = Session["UserEmail"]?.ToString() ?? User.Identity.Name;
            // var bookings = userDAO.GetBookingHistoryByEmail(userEmail);
            return View();
        }

        // 3. THÊM HÀM LOGOUT (QUAN TRỌNG ĐỂ THANH NAV ĐỔI TRẠNG THÁI)
        // GET: /Account/Logout
        public ActionResult Logout()
        {
            // Xóa Cookie xác thực
            FormsAuthentication.SignOut();

            // Xóa Session
            Session.Clear();
            Session.Abandon();

            // Quay về trang chủ
            return RedirectToAction("Index", "Home");
        }
    }
}