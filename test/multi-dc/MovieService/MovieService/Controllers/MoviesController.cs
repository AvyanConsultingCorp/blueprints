using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Entity;
using System.Data.Entity.Infrastructure;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Description;
using System.Web.UI.WebControls;
using MovieService.Models;

namespace MovieService.Controllers
{
    public class MoviesController : ApiController
    {
        private readonly MovieServiceContext _db = new MovieServiceContext();

        // GET: api/Movies
        public IQueryable<Movie> GetMovies()
        {
            return _db.Movies;
        }

        // GET: api/Movies/5
        [ResponseType(typeof(Movie))]
        public async Task<IHttpActionResult> GetMovie(int id)
        {
            Movie movie = await _db.Movies.FindAsync(id);
            if (movie == null)
            {
                return NotFound();
            }

            return Ok(movie);
        }

        // PUT: api/Movies/5
        [ResponseType(typeof(void))]
        public async Task<IHttpActionResult> PutMovie(int id, Movie movie)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            if (id != movie.Id)
            {
                return BadRequest();
            }

            _db.Entry(movie).State = EntityState.Modified;

            try
            {
                await _db.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!MovieExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return StatusCode(HttpStatusCode.NoContent);
        }

        // POST: api/Movies
        [ResponseType(typeof(Movie))]
        public async Task<IHttpActionResult> PostMovie(Movie movie)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            _db.Movies.Add(movie);
            await _db.SaveChangesAsync();

            return CreatedAtRoute("DefaultApi", new { id = movie.Id }, movie);
        }

        // DELETE: api/Movies/5
        [ResponseType(typeof(Movie))]
        public async Task<IHttpActionResult> DeleteMovie(int id)
        {
            Movie movie = await _db.Movies.FindAsync(id);
            if (movie == null)
            {
                return NotFound();
            }

            _db.Movies.Remove(movie);
            await _db.SaveChangesAsync();

            return Ok(movie);
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                _db.Dispose();
            }
            base.Dispose(disposing);
        }

        private bool MovieExists(int id)
        {
            return _db.Movies.Count(e => e.Id == id) > 0;
        }
    }
}