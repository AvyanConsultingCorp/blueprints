using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading;
using System.Threading.Tasks;
using MovieService.Models;
using MovieService.Core;

namespace MovieService.Frontend
{
    public class Program
    {
        private const string EndPointUri = "http://moviemania.azurewebsites.net/";
        private static readonly Random Randomizer = new Random();
        private static readonly Array MovieGenres = Enum.GetValues(typeof (GenreType));

        static void Main(string[] args)
        {
            var options = new Dictionary<string, Func<CancellationToken, Task>>()
            {
                {"Add a movie", AddMovieAsync},

                {"Update a movie", UpdateMovieAsync},

                {"Delete a movie", DeleteMovieAsync},

                {"Add a person", AddPersonAsync},

                {"Update a person", UpdatePersonAsync},

                {"Delete a person", DeletePersonAsync},

                { "List movies", ListMoviesAsync},

                { "List persons", ListPersonsAsync}
            };

            ConsoleHost.RunWithOptionsAsync(options).Wait();
        }

        private static Task ListPersonsAsync(CancellationToken arg)
        {
            throw new NotImplementedException();
        }

        private static async Task<IEnumerable<Movie>> ListMoviesAsync(CancellationToken arg)
        {
            using (var client = new HttpClient())
            {
                client.BaseAddress = new Uri(EndPointUri);
                client.DefaultRequestHeaders.Accept.Clear();
                client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                var response = await client.GetAsync("api/Movies", arg);

                if (!response.IsSuccessStatusCode) return null;
                return await response.Content.ReadAsAsync<IEnumerable<Movie>>(arg);
            }
        }

        private static Task DeletePersonAsync(CancellationToken arg)
        {
            throw new NotImplementedException();
        }

        private static Task UpdatePersonAsync(CancellationToken arg)
        {
            throw new NotImplementedException();
        }

        private static Task AddPersonAsync(CancellationToken arg)
        {
            throw new NotImplementedException();
        }

        private static Task DeleteMovieAsync(CancellationToken arg)
        {
            throw new NotImplementedException();
        }

        private static Task UpdateMovieAsync(CancellationToken arg)
        {
            throw new NotImplementedException();
        }

        private static async Task AddMovieAsync(CancellationToken arg)
        {
            var movie = new Movie()
            {
                Id = await GetLastMovieId(arg) + 1,
                Title = string.Concat("Poltergeist_", Randomizer.Next(1, 5000)),
                Genre = (GenreType) MovieGenres.GetValue(Randomizer.Next(MovieGenres.Length)),
                ReleaseYear = (ushort) Randomizer.Next(1900, 2017),
                RunningTime = new TimeSpan(Randomizer.Next(1, 3), Randomizer.Next(1, 60), Randomizer.Next(1, 60))
            };

            using (var client = new HttpClient())
            {
                client.BaseAddress = new Uri(EndPointUri);
                client.DefaultRequestHeaders.Accept.Clear();
                client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
                await client.PostAsJsonAsync("api/Movies", movie, arg);
            }
        }

        private static async Task<int> GetLastMovieId(CancellationToken token)
        {
            var movies = await ListMoviesAsync(token);

            if (null != movies)
            {
                var enumerable = movies as IList<Movie> ?? movies.ToList();
                return !enumerable.Any() ? 0 : enumerable.OrderByDescending(m => m.Id).First().Id;
            }

            return -1;
        }
    }
}
