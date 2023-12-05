// Jacky lee April 30
const datediff  = function(firstDate, secondDate) {
    const dateRemain = Math.round((secondDate - firstDate) / (1000 * 60 * 60 * 24)) + 1;
    if (dateRemain < 0 ) return 0;
    else return dateRemain;
}

export {
    datediff
}