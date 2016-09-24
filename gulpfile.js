var gulp = require('gulp'),
    coffee = require('gulp-coffee'),
    gutil = require('gulp-util'),
    browserify = require('browserify'),
    coffeeify = require('coffeeify'),
    uglify = require('gulp-uglify'),
    source = require('vinyl-source-stream'),
    buffer = require('vinyl-buffer'),
    download = require('gulp-download'),
    request = require('request'),
    replace = require('gulp-replace'),
    rename = require('gulp-rename'),
    webserver = require('gulp-webserver');

var coffeeStream = coffee({bare: true});
coffeeStream.on('error', gutil.log);

var CMM_RELEASE_URL = 'https://github.com/jutge-org/cmm/releases/latest';

gulp.task('import-release', () => {
    var options = {
        url: 'https://api.github.com/repos/jutge-org/cmm/releases/latest',
        headers: {
            'User-Agent': 'Mozilla/5.0'
        }
    };
    request(options, (error, response, body) => {
        if (!error && response.statusCode === 200) {
            var JSONresponse = JSON.parse(body)
            download(JSONresponse['assets'][0]['browser_download_url'])
                .pipe(gulp.dest('./js'))
        } else {
            console.log(response.statusCode)
            throw "Couldn't connect to API"
        }
    });
});

gulp.task('compile-main', () => {
    gulp.src('./js/main.coffee')
        .pipe(coffee({}).on('error', gutil.log))
        .pipe(uglify())
        .pipe(rename({ suffix: '.min' }))
        .pipe(gulp.dest('./js'));
});

gulp.task('browserify-run', () => {
    return browserify('./js/run.coffee', {extensions:['.coffee']})
        .transform(coffeeify)
        .bundle()
        .pipe(source('run.min.js'))
        .pipe(replace('onmessage, ', ''))
        .pipe(buffer())
        .pipe(uglify())
        .pipe(gulp.dest('./js'))
});

gulp.task('dev', ['compile-main', 'browserify-run'], () => {
    gulp.src('./')
        .pipe(webserver({
            livereload: true,
            open: true
        }))
});

gulp.task('default', ['import-release', 'compile-main', 'browserify-run'], () => {
});
