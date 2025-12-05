using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web.Mvc;
using Tour_Website.DAL;
using Tour_Website.ViewModels;

namespace Tour_Website.Controllers
{
    [Authorize]
    public class CartController : Controller
    {
        private readonly UserDAO userDAO = new UserDAO();
        private readonly string connectionString = ConfigurationManager.ConnectionStrings["TourProject_Database1"].ConnectionString;

        // GET: /Cart/CartIndex
        [HttpGet]
        [AllowAnonymous]
        public ActionResult CartIndex()
        {
            if (!User.Identity.IsAuthenticated)
            {
                return RedirectToAction("Login", "Account", new { returnUrl = Url.Action("Index", "Cart") });
            }

            var email = Session["UserEmail"]?.ToString() ?? User.Identity.Name;
            var user = userDAO.GetUserByEmail(email);
            if (user == null)
            {
                return RedirectToAction("Login", "Account");
            }

            var vm = new CartViewModel();

            using (var conn = new SqlConnection(connectionString))
            {
                conn.Open();

                // get cart id
                int? cartId = null;
                using (var cmd = new SqlCommand("SELECT CartID FROM Cart WHERE UserID = @UserID", conn))
                {
                    cmd.Parameters.AddWithValue("@UserID", user.UserID);
                    var scalar = cmd.ExecuteScalar();
                    if (scalar != null && scalar != DBNull.Value)
                        cartId = Convert.ToInt32(scalar);
                }

                if (!cartId.HasValue)
                    return View(vm); // empty cart

                vm.CartId = cartId;

                // get cart items with tour info
                using (var cmd = new SqlCommand(@"
                    SELECT ci.CartItemID, ci.TourID, ci.Quantity, ci.UnitPrice,
                           ISNULL(t.TourName, '') AS TourName,
                           ISNULL(t.AvatarUrl, '') AS AvatarUrl
                    FROM CartItem ci
                    LEFT JOIN Tour t ON ci.TourID = t.TourID
                    WHERE ci.CartID = @CartID
                    ORDER BY ci.CartItemID", conn))
                {
                    cmd.Parameters.AddWithValue("@CartID", cartId.Value);
                    using (var rdr = cmd.ExecuteReader())
                    {
                        while (rdr.Read())
                        {
                            var item = new CartItemViewModel
                            {
                                CartItemId = rdr.GetInt32(rdr.GetOrdinal("CartItemID")),
                                TourId = rdr.GetInt32(rdr.GetOrdinal("TourID")),
                                TourName = rdr.GetString(rdr.GetOrdinal("TourName")),
                                AvatarUrl = string.IsNullOrWhiteSpace(rdr.GetString(rdr.GetOrdinal("AvatarUrl")))
                                    ? "/Content/images/Tour/default.jpg"
                                    : "/Content/images/Tour/" + rdr.GetString(rdr.GetOrdinal("AvatarUrl")).TrimStart('\\', '/'),
                                UnitPrice = rdr["UnitPrice"] != DBNull.Value ? Convert.ToDecimal(rdr["UnitPrice"]) : 0m,
                                Quantity = rdr["Quantity"] != DBNull.Value ? Convert.ToInt32(rdr["Quantity"]) : 1
                            };
                            vm.Items.Add(item);
                        }
                    }
                }
            }

            return View(vm);
        }

        // POST: /Cart/AddToCart
        [HttpPost]
        [AllowAnonymous]
        public ActionResult AddToCart(int tourId, int quantity = 1)
        {
            if (quantity <= 0) quantity = 1;

            var email = Session["UserEmail"]?.ToString() ?? (User.Identity.IsAuthenticated ? User.Identity.Name : null);
            if (string.IsNullOrWhiteSpace(email))
                return Json(new { success = false, message = "Vui lòng đăng nhập để thêm tour vào giỏ hàng.", cartCount = 0, requiresLogin = true });

            var user = userDAO.GetUserByEmail(email);
            if (user == null)
                return Json(new { success = false, message = "Không tìm thấy người dùng.", cartCount = 0 });

            int cartId;
            using (var conn = new SqlConnection(connectionString))
            {
                conn.Open();
                using (var tx = conn.BeginTransaction())
                {
                    try
                    {
                        // ensure cart exists
                        using (var cmd = new SqlCommand("SELECT CartID FROM Cart WHERE UserID = @UserID", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@UserID", user.UserID);
                            var scalar = cmd.ExecuteScalar();
                            if (scalar == null || scalar == DBNull.Value)
                            {
                                using (var ins = new SqlCommand("INSERT INTO Cart (UserID, CreatedAt) VALUES (@UserID, SYSUTCDATETIME()); SELECT SCOPE_IDENTITY()", conn, tx))
                                {
                                    ins.Parameters.AddWithValue("@UserID", user.UserID);
                                    cartId = Convert.ToInt32(ins.ExecuteScalar());
                                }
                            }
                            else
                            {
                                cartId = Convert.ToInt32(scalar);
                            }
                        }

                        // get tour price
                        decimal unitPrice;
                        using (var cmd = new SqlCommand("SELECT Price FROM Tour WHERE TourID = @TourID", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@TourID", tourId);
                            var p = cmd.ExecuteScalar();
                            if (p == null || p == DBNull.Value)
                                throw new Exception("Tour không tồn tại.");
                            unitPrice = Convert.ToDecimal(p);
                        }

                        // check existing cart item
                        int? existingCartItemId = null;
                        int existingQty = 0;
                        using (var cmd = new SqlCommand("SELECT CartItemID, Quantity FROM CartItem WHERE CartID = @CartID AND TourID = @TourID", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@CartID", cartId);
                            cmd.Parameters.AddWithValue("@TourID", tourId);
                            using (var rdr = cmd.ExecuteReader())
                            {
                                if (rdr.Read())
                                {
                                    existingCartItemId = Convert.ToInt32(rdr["CartItemID"]);
                                    existingQty = rdr["Quantity"] != DBNull.Value ? Convert.ToInt32(rdr["Quantity"]) : 0;
                                }
                            }
                        }

                        if (existingCartItemId.HasValue)
                        {
                            using (var cmd = new SqlCommand("UPDATE CartItem SET Quantity = @Quantity, UnitPrice = @UnitPrice WHERE CartItemID = @Id", conn, tx))
                            {
                                cmd.Parameters.AddWithValue("@Quantity", existingQty + quantity);
                                cmd.Parameters.AddWithValue("@UnitPrice", unitPrice);
                                cmd.Parameters.AddWithValue("@Id", existingCartItemId.Value);
                                cmd.ExecuteNonQuery();
                            }
                        }
                        else
                        {
                            using (var cmd = new SqlCommand("INSERT INTO CartItem (CartID, TourID, Quantity, UnitPrice) VALUES (@CartID, @TourID, @Quantity, @UnitPrice)", conn, tx))
                            {
                                cmd.Parameters.AddWithValue("@CartID", cartId);
                                cmd.Parameters.AddWithValue("@TourID", tourId);
                                cmd.Parameters.AddWithValue("@Quantity", quantity);
                                cmd.Parameters.AddWithValue("@UnitPrice", unitPrice);
                                cmd.ExecuteNonQuery();
                            }
                        }

                        tx.Commit();

                        // compute cart count
                        int cartCount = 0;
                        using (var cmd = new SqlCommand("SELECT SUM(Quantity) FROM CartItem WHERE CartID = @CartID", conn))
                        {
                            cmd.Parameters.AddWithValue("@CartID", cartId);
                            var s = cmd.ExecuteScalar();
                            cartCount = s != DBNull.Value && s != null ? Convert.ToInt32(s) : 0;
                        }

                        return Json(new { success = true, message = "Đã thêm tour vào giỏ hàng.", cartCount = cartCount });
                    }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Debug.WriteLine("Cart error: " + ex.ToString());
                        try { tx.Rollback(); } catch { }
                        return Json(new { success = false, message = ex.Message });
                    }
                }
            }
        }

        // POST: /Cart/UpdateQuantity
        [HttpPost]
        public ActionResult UpdateQuantity(int cartItemId, int quantity)
        {
            if (quantity < 0) quantity = 0;

            using (var conn = new SqlConnection(connectionString))
            {
                conn.Open();
                using (var tx = conn.BeginTransaction())
                {
                    try
                    {
                        int? cartId = null;
                        using (var cmd = new SqlCommand("SELECT CartID FROM CartItem WHERE CartItemID = @Id", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Id", cartItemId);
                            var s = cmd.ExecuteScalar();
                            if (s == null) return Json(new { success = false, message = "Mục giỏ hàng không tồn tại." });
                            cartId = Convert.ToInt32(s);
                        }

                        if (quantity == 0)
                        {
                            using (var cmd = new SqlCommand("DELETE FROM CartItem WHERE CartItemID = @Id", conn, tx))
                            {
                                cmd.Parameters.AddWithValue("@Id", cartItemId);
                                cmd.ExecuteNonQuery();
                            }
                        }
                        else
                        {
                            using (var cmd = new SqlCommand("UPDATE CartItem SET Quantity = @Quantity WHERE CartItemID = @Id", conn, tx))
                            {
                                cmd.Parameters.AddWithValue("@Quantity", quantity);
                                cmd.Parameters.AddWithValue("@Id", cartItemId);
                                cmd.ExecuteNonQuery();
                            }
                        }

                        tx.Commit();

                        // new totals
                        decimal total = 0m;
                        int cartCount = 0;
                        using (var cmd = new SqlCommand("SELECT SUM(Quantity * UnitPrice) FROM CartItem WHERE CartID = @CartID", conn))
                        {
                            cmd.Parameters.AddWithValue("@CartID", cartId);
                            var s = cmd.ExecuteScalar();
                            total = s != DBNull.Value && s != null ? Convert.ToDecimal(s) : 0m;
                        }
                        using (var cmd = new SqlCommand("SELECT SUM(Quantity) FROM CartItem WHERE CartID = @CartID", conn))
                        {
                            cmd.Parameters.AddWithValue("@CartID", cartId);
                            var s = cmd.ExecuteScalar();
                            cartCount = s != DBNull.Value && s != null ? Convert.ToInt32(s) : 0;
                        }

                        // item subtotal (if still exists)
                        decimal itemSubtotal = 0m;
                        using (var cmd = new SqlCommand("SELECT Quantity * UnitPrice FROM CartItem WHERE CartItemID = @Id", conn))
                        {
                            cmd.Parameters.AddWithValue("@Id", cartItemId);
                            var s = cmd.ExecuteScalar();
                            itemSubtotal = s != DBNull.Value && s != null ? Convert.ToDecimal(s) : 0m;
                        }

                        return Json(new { success = true, total = total, itemSubtotal = itemSubtotal, cartCount = cartCount });
                    }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Debug.WriteLine("Cart error: " + ex.ToString());
                        try { tx.Rollback(); } catch { }
                        return Json(new { success = false, message = ex.Message });
                    }
                }
            }
        }

        // POST: /Cart/RemoveFromCart
        [HttpPost]
        public ActionResult RemoveFromCart(int cartItemId)
        {
            using (var conn = new SqlConnection(connectionString))
            {
                conn.Open();
                using (var tx = conn.BeginTransaction())
                {
                    try
                    {
                        int? cartId = null;
                        using (var cmd = new SqlCommand("SELECT CartID FROM CartItem WHERE CartItemID = @Id", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Id", cartItemId);
                            var s = cmd.ExecuteScalar();
                            if (s == null) return Json(new { success = false, message = "Mục giỏ hàng không tồn tại." });
                            cartId = Convert.ToInt32(s);
                        }

                        using (var cmd = new SqlCommand("DELETE FROM CartItem WHERE CartItemID = @Id", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Id", cartItemId);
                            cmd.ExecuteNonQuery();
                        }

                        tx.Commit();

                        decimal total = 0m;
                        int cartCount = 0;
                        using (var cmd = new SqlCommand("SELECT SUM(Quantity * UnitPrice) FROM CartItem WHERE CartID = @CartID", conn))
                        {
                            cmd.Parameters.AddWithValue("@CartID", cartId);
                            var s = cmd.ExecuteScalar();
                            total = s != DBNull.Value && s != null ? Convert.ToDecimal(s) : 0m;
                        }
                        using (var cmd = new SqlCommand("SELECT SUM(Quantity) FROM CartItem WHERE CartID = @CartID", conn))
                        {
                            cmd.Parameters.AddWithValue("@CartID", cartId);
                            var s = cmd.ExecuteScalar();
                            cartCount = s != DBNull.Value && s != null ? Convert.ToInt32(s) : 0;
                        }

                        return Json(new { success = true, total = total, cartCount = cartCount });
                    }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Debug.WriteLine("Cart error: " + ex.ToString());
                        try { tx.Rollback(); } catch { }
                        return Json(new { success = false, message = ex.Message });
                    }
                }
            }
        }

        // GET: /Cart
        [AllowAnonymous]
        public ActionResult Index()
        {
            // Redirect to the existing CartIndex action so /Cart or layout link works
            return RedirectToAction("CartIndex");
        }

        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);
        }
    }
}