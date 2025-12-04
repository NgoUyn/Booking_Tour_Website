using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Tour_Website.Models;
using Tour_Website.ViewModels;
using System.Text;


namespace Tour_Website.Controllers
{
    public class TravelController : Controller
    {
        private TourProject_Database db = new TourProject_Database();
        // GET: Travel

        public ActionResult TuTuc()
        {
            var categories = GetCategoryOptions();
            var placeCards = db.Places
                .AsEnumerable()
                .Select(p => BuildPlaceCard(p, categories))
                .OrderByDescending(p => p.Rating)
                .Take(30)
                .ToList();

            var viewModel = new TuTucViewModel
            {
                Categories = categories,
                Places = placeCards
            };

            return View(viewModel);
        }

        [HttpGet]
        public JsonResult SearchPlaces(string query)
        {
            var categories = GetCategoryOptions();
            var normalizedQuery = (query ?? string.Empty).Trim().ToLowerInvariant();

            var matches = db.Places
                .AsEnumerable()
                .Where(p => string.IsNullOrEmpty(normalizedQuery) ||
                    GetStringPropertyValue(p, string.Empty, "Name", "Title").ToLowerInvariant().Contains(normalizedQuery))
                .Select(p => BuildPlaceCard(p, categories))
                .OrderByDescending(p => p.Rating)
                .Take(30)
                .ToList();

            return Json(matches, JsonRequestBehavior.AllowGet);
        }

        [HttpGet]
        public JsonResult SuggestPlaces(string term)
        {
            var normalized = (term ?? string.Empty).Trim();
            if (string.IsNullOrEmpty(normalized))
            {
                return Json(new object[0], JsonRequestBehavior.AllowGet);
            }

            var normalizedLower = normalized.ToLowerInvariant();

            var matches = db.Places
                .AsEnumerable()
                .Where(p => GetStringPropertyValue(p, string.Empty, "Name", "Title")
                    .ToLowerInvariant()
                    .Contains(normalizedLower))
                .OrderByDescending(p => GetDoublePropertyValue(p, 0, "Rating"))
                .Take(6)
                .Select(p => new
                {
                    placeId = GetIntPropertyValue(p, 0, "PlaceID", "Id"),
                    name = GetStringPropertyValue(p, "Unknown place", "Name", "Title"),
                    rating = GetDoublePropertyValue(p, 0, "Rating")
                })
                .ToList();

            return Json(matches, JsonRequestBehavior.AllowGet);
        }

        private List<TuTucViewModel.CategoryOption> GetCategoryOptions()
        {
            return db.Categories
                .AsEnumerable()
                .Select(c => new TuTucViewModel.CategoryOption
                {
                    CategoryId = c.CategoryID,
                    Name = c.CategoryName,
                    Slug = GenerateSlug(c.CategoryName)
                })
                .OrderBy(c => c.Name)
                .ToList();
        }

        private TuTucViewModel.PlaceCard BuildPlaceCard(Place place, List<TuTucViewModel.CategoryOption> categoryOptions)
        {
            var imageFiles = GetPlaceImageUrls(place.PlaceID);
            var primaryPhoto = imageFiles.FirstOrDefault() ??
                GetStringPropertyValue(place, "https://via.placeholder.com/100", "AvatarUrl", "PhotoUrl");

            var categoryId = GetIntPropertyValue(place, 0, "CategoryID", "CategoryId");
            var category = categoryOptions.FirstOrDefault(c => c.CategoryId == categoryId);

            return new TuTucViewModel.PlaceCard
            {
                PlaceId = GetIntPropertyValue(place, 0, "PlaceID", "Id"),
                Name = GetStringPropertyValue(place, "Unknown place", "Name", "Title"),
                Address = GetStringPropertyValue(place, "No address provided", "Address"),
                Latitude = GetDoublePropertyValue(place, 0, "Latitude", "Lat"),
                Longitude = GetDoublePropertyValue(place, 0, "Longitude", "Lng", "Long"),
                Rating = GetDoublePropertyValue(place, 0, "Rating"),
                Reviews = GetIntPropertyValue(place, 0, "UserRatingsTotal", "ReviewCount"),
                PhotoUrl = primaryPhoto,
                ImageUrls = imageFiles,
                CategorySlug = category?.Slug ?? "other",
                CategoryName = category?.Name ?? "Other",
                Distance = null
            };
        }

        private List<string> GetPlaceImageUrls(long placeId)
        {
            return db.PlaceImages
                .Where(pi => pi.PlaceID == placeId)
                .Select(pi => pi.Url)
                .ToList()
                .Where(url => !string.IsNullOrWhiteSpace(url))
                .Select(url => "/Content/images/PlaceImage/" + url.TrimStart('\\', '/'))
                .ToList();
        }

        private static string GenerateSlug(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return "category";

            var builder = new StringBuilder();
            foreach (var ch in text.ToLowerInvariant())
            {
                if (char.IsLetterOrDigit(ch))
                    builder.Append(ch);
                
                else if (builder.Length > 0 && builder[builder.Length - 1] != '-')
                    builder.Append('-');
            }

            var slug = builder.ToString().Trim('-');
            return string.IsNullOrEmpty(slug) ? "category" : slug;
        }

        private static string GetStringPropertyValue(object entity, string fallback, params string[] names)
        {
            foreach (var name in names)
            {
                var prop = entity.GetType().GetProperty(name);
                if (prop != null)
                {
                    var value = prop.GetValue(entity);
                    if (value is string str && !string.IsNullOrWhiteSpace(str))
                        return str;
                }
            }
            return fallback;
        }

        private static double GetDoublePropertyValue(object entity, double fallback, params string[] names)
        {
            var candidate = TryGetNumericValue(entity, names);
            if (!double.IsNaN(candidate))
                return candidate;

            var keywords = new[] { "rating", "rate", "score", "point", "value" };
            foreach (var prop in entity.GetType().GetProperties())
            {
                if (keywords.Any(k => prop.Name.IndexOf(k, StringComparison.OrdinalIgnoreCase) >= 0))
                {
                    var parsed = TryParseNumeric(prop.GetValue(entity));
                    if (parsed.HasValue)
                        return parsed.Value;
                }
            }

            return fallback;
        }

        private static double TryGetNumericValue(object entity, params string[] names)
        {
            foreach (var name in names)
            {
                var prop = entity.GetType().GetProperty(name);
                if (prop == null)
                    continue;
                var parsed = TryParseNumeric(prop.GetValue(entity));
                if (parsed.HasValue)
                    return parsed.Value;
            }
            return double.NaN;
        }

        private static double? TryParseNumeric(object value)
        {
            if (value == null)
                return null;
            if (value is double d)
                return d;
            if (value is float f)
                return f;
            if (value is decimal dec)
                return (double)dec;
            if (double.TryParse(value.ToString(), NumberStyles.Any, CultureInfo.InvariantCulture, out var result))
                return result;
            return null;
        }

        private static int GetIntPropertyValue(object entity, int fallback, params string[] names)
        {
            foreach (var name in names)
            {
                var prop = entity.GetType().GetProperty(name);
                if (prop != null)
                {
                    var value = prop.GetValue(entity);
                    if (value != null && int.TryParse(value.ToString(), out var result))
                        return result;
                }
            }
            return fallback;
        }

        public ActionResult TourNhom()
        {
            var categories = db.Categories
                .Where(c => c.IsActive == true)
                .OrderBy(c => c.CategoryName)
                .ToList();

            var categoryLookup = categories
    .ToDictionary(c => c.CategoryID, c => c.CategoryName ?? "Tour");

            var itineraries = db.TourItineraries
                .ToList()
                .GroupBy(i => i.TourID)
                .ToDictionary(
                    g => g.Key,
                    g => g.OrderBy(x => x.DayNumber).Select(x => new TourNhomViewModel.ItineraryItem
                    {
                        DayNumber = x.DayNumber.GetValueOrDefault(),
                        Title = x.Title ?? string.Empty,
                        Description = x.Description ?? string.Empty
                    }).ToList()
                );

            var soldLookup = db.OrderDetails
                .Join(db.Tours, od => od.TourID, t => t.TourID, (od, t) => od)
                .GroupBy(od => od.TourID)
                .ToDictionary(g => g.Key, g => g.Sum(od => od.Quantity));

            var tourCards = db.Tours
                .Where(t => (t.Status ?? 0) == 1)
                .OrderByDescending(t => t.CreatedAt)
                .ToList()
                .Select(t =>
                {
                    var imageFile = string.IsNullOrWhiteSpace(t.AvatarUrl)
                        ? "default.jpg"
                        : t.AvatarUrl.TrimStart('\\', '/');

                    var categoryName = categoryLookup.TryGetValue(t.CategoryID.GetValueOrDefault(), out var name)
                        ? name
                        : "Tour";

                    var itineraryList = itineraries.TryGetValue(t.TourID, out var list) ? list : new List<TourNhomViewModel.ItineraryItem>();
                    var soldCount = soldLookup.TryGetValue(t.TourID, out var sold) ? sold : 0;

                    return new TourNhomViewModel.TourCard
                    {
                        TourId = t.TourID,
                        TourName = t.TourName ?? "Tour",
                        Description = t.Description ?? string.Empty,
                        Duration = t.Duration ?? "N/A",
                        Price = t.Price.GetValueOrDefault(),
                        TotalSlots = t.TotalSlots.GetValueOrDefault(),
                        AvailableSlots = t.AvailableSlots.GetValueOrDefault(),
                        AvatarUrl = $"/Content/images/Tour/{imageFile}",
                        CategoryName = categoryName,
                        Itinerary = itineraryList,
                        SoldCount = soldCount.GetValueOrDefault() // <-- FIXED HERE
                    };
                })
                .ToList();

            var viewModel = new TourNhomViewModel
            {
                Categories = categories.Select(c => new TourNhomViewModel.CategoryOption
                {
                    CategoryId = c.CategoryID,
                    Name = c.CategoryName ?? "Category",
                    Slug = (c.CategoryName ?? "category").Replace(" ", "-").ToLowerInvariant()
                }).ToList(),
                Tours = tourCards
            };

            return View(viewModel);
        }

        [HttpPost]
        public JsonResult AddToCart(int tourId, int quantity = 1)
        {
            if (!User.Identity.IsAuthenticated)
            {
                return Json(new { success = false, message = "Vui lòng đăng nhập để thêm tour vào giỏ hàng.", cartCount = 0 });
            }

            var userEmail = Session["UserEmail"]?.ToString() ?? User.Identity.Name;
            var user = db.Users.FirstOrDefault(u => u.Email == userEmail);
            if (user == null)
            {
                return Json(new { success = false, message = "Không tìm thấy thông tin người dùng.", cartCount = 0 });
            }

            var tour = db.Tours.Find(tourId);
            if (tour == null)
            {
                return Json(new { success = false, message = "Tour không tồn tại.", cartCount = 0 });
            }

            if (quantity <= 0) quantity = 1;

            var cart = db.Carts.FirstOrDefault(c => c.UserID == user.UserID);
            if (cart == null)
            {
                cart = new Cart
                {
                    UserID = user.UserID,
                    CreatedAt = DateTimeOffset.Now
                };
                db.Carts.Add(cart);
            }

            var cartItem = db.CartItems.FirstOrDefault(ci => ci.CartID == cart.CartID && ci.TourID == tourId);
            if (cartItem != null)
            {
                cartItem.Quantity += quantity;
            }
            else
            {
                cartItem = new CartItem
                {
                    CartID = cart.CartID,
                    TourID = tourId,
                    Quantity = quantity,
                    UnitPrice = tour.Price
                };
                db.CartItems.Add(cartItem);
            }

            db.SaveChanges();

            var cartCount = db.CartItems
                .Where(ci => ci.CartID == cart.CartID)
                .Select(ci => (int?)ci.Quantity)
                .Sum() ?? 0;

            return Json(new
            {
                success = true,
                message = $"Đã thêm '{tour.TourName}' vào giỏ hàng.",
                cartCount = cartCount
            });
        }
    }
}