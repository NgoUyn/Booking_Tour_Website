using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Tour_Website.Models;
using Tour_Website.ViewModels;


namespace Tour_Website.Controllers
{
    public class TravelController : Controller
    {
        private TourProject_Database db = new TourProject_Database();
        // GET: Travel

        public ActionResult TuTuc()
        {
            return View();
        }

        public ActionResult TourNhom()
        {
            return View();
        }
    }
}