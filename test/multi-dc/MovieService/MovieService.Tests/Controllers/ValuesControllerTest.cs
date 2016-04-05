using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Web.Http;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MovieService;
using MovieService.Controllers;
using MovieService.Models;

namespace MovieService.Tests.Controllers
{
    [TestClass]
    public class ValuesControllerTest
    {
        [TestMethod]
        public void Get()
        {
            // Arrange
            var controller = new MoviesController();

            // Act
            var result = controller.GetMovies();

            // Assert
            Assert.IsNotNull(result);
            Assert.AreEqual(2, result.Count());
            Assert.AreEqual("value1", result.ElementAt(0));
            Assert.AreEqual("value2", result.ElementAt(1));
        }

        [TestMethod]
        public void GetById()
        {
            // Arrange
            var controller = new MoviesController();
            
            // Act
            var result = controller.GetMovie(5);

            // Assert
            Assert.AreEqual("value", result);
        }

    }
}
